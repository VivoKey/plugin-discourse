module VivoKey
  module Extensions
    module DisableLocalLoginsForAccountsConnectedToVivoKey
      HINT = 'You must log in using your VivoKey.'.freeze

      module SessionController
        protected

        def login(user)
          unless user.user_associated_accounts.where(provider_name: 'vivokey').exists?
            return super
          end

          return render json: failed_json.merge(error: HINT)
        end
      end

      module UserNotifications
        def forgot_password(user, opts = {})
          if user.user_associated_accounts.where(provider_name: 'vivokey').exists?
            build_email(
              user.email,
              template: user.has_password? ? "vivokey.forgot_password" : "vivokey.set_password",
              locale: user_locale(user)
            )
          else
            super(user, opts)
          end
        end

        def email_login(user, opts = {})
          if user.user_associated_accounts.where(provider_name: 'vivokey').exists?
            build_email(
              user.email,
              template: "vivokey.email_login",
              locale: user_locale(user)
            )
          else
            super(user, opts)
          end
        end
      end
    end
  end
end
