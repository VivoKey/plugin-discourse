require_relative "omniauth_vivokey_open_id"

class VivoKeyAuthenticator < Auth::ManagedAuthenticator
  VIVOKEY_OPENID_DISCOVERY_DOCUMENT = 'https://api.vivokey.com/openid/.well-known/openid-configuration'
  VIVOKEY_OPENID_AUTHORIZE_SCOPE = 'openid email'

  def name
    'vivokey'
  end

  def can_revoke?
    SiteSetting.vivokey_openid_allow_disconnect
  end

  def can_connect_existing_user?
    SiteSetting.vivokey_openid_allow_connect
  end

  def enabled?
    SiteSetting.vivokey_openid_enabled
  end

  def match_by_email
    false
  end

  def register_middleware(omniauth)
    omniauth.provider :vivokey_openid,
      name: :vivokey,
      cache: lambda { |key, &blk| Rails.cache.fetch(key, expires_in: 10.minutes, &blk) },
      error_handler: lambda { |error, message|
        handlers = SiteSetting.vivokey_openid_error_redirects.split("\n")
        handlers.each do |row|
          parts = row.split("|")
          return parts[1] if message.include? parts[0]
        end
        nil
      },
      verbose_logger: lambda { |message|
        return unless SiteSetting.vivokey_openid_verbose_logging
        Rails.logger.warn("VivoKey OIDC Log: #{message}")
      },
      setup: lambda { |env|
        opts = env['omniauth.strategy'].options
        opts.deep_merge!(
          client_id: SiteSetting.vivokey_openid_client_id,
          client_secret: SiteSetting.vivokey_openid_client_secret,
          client_options: {
            discovery_document: VIVOKEY_OPENID_DISCOVERY_DOCUMENT,
          },
          scope: VIVOKEY_OPENID_AUTHORIZE_SCOPE,
          token_params: {
            scope: SiteSetting.vivokey_openid_token_scope,
          }
        )
      }
  end

  def after_authenticate(auth_token, existing_account: nil)
    result = super(auth_token, existing_account: existing_account)

    # Do not consider unverified emails to be valid
    email_verified = !!auth_token[:extra][:raw_info][:email_verified]
    result.email_valid &&= email_verified

    # Fail authentication if no matching account found and registration is not allowed
    if !result.user && !SiteSetting.vivokey_openid_registration
      result.failed = true
      result.failed_reason = I18n.t("vivokey_openid.registration_not_allowed")
    end

    # If logged in with email taken by another user
    if result.user.nil? && (user = User.find_by_email(auth_token.dig(:info, :email)))
      # and matching by email is disabled
      unless match_by_email
        # mark email as invalid
        result.email_valid = false
      end
    end

    result
  end
end
