require_relative "omniauth_vivokey_open_id"

class VivoKeyAuthenticator < Auth::ManagedAuthenticator
  def name
    'vivokey'
  end

  def can_revoke?
    SiteSetting.vivokey_openid_allow_association_change
  end

  def can_connect_existing_user?
    SiteSetting.vivokey_openid_allow_association_change
  end

  def enabled?
    SiteSetting.vivokey_openid_enabled
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
            discovery_document: SiteSetting.vivokey_openid_discovery_document,
          },
          scope: SiteSetting.vivokey_openid_authorize_scope,
          token_params: {
            scope: SiteSetting.vivokey_openid_token_scope,
          }
        )
      }
  end

  def after_authenticate(auth_token, existing_account: nil)
    result = super(auth_token, existing_account: existing_account)

    # do not consider unverified emails to be valid
    email_verified = !!auth_token[:extra][:raw_info][:email_verified]
    result.email_valid &&= email_verified

    result
  end
end
