module VivoKey
  module Extensions
    module RelaxInviteOnly
      AUTHENTICATOR_NAME = 'vivokey'.freeze

      module Users
        module OmniauthCallbacksController
          protected

          def complete_response_data
            is_vivokey = @auth_result.session_data.present? &&
              @auth_result.session_data[:authenticator_name] == AUTHENTICATOR_NAME

            if @auth_result.user
              user_found(@auth_result.user)
            elsif SiteSetting.invite_only? && !is_vivokey
              @auth_result.requires_invite = true
            else
              session[:authentication] = @auth_result.session_data
            end
          end
        end
      end

      module UsersController
        private

        def suspicious?(params)
          is_suspicious = super(params)
          return is_suspicious unless vivokey?

          is_suspicious && honeypot_or_challenge_fails?(params)
        end

        def vivokey?
          session.present? && session[:authentication].present? &&
            session[:authentication][:authenticator_name] == AUTHENTICATOR_NAME
        end
      end
    end
  end
end
