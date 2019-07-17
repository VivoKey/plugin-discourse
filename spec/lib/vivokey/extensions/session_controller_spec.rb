require 'rails_helper'

describe SessionController, type: :controller do
  describe '#create' do
    let(:user) { Fabricate(:user) }

    describe 'by username' do
      before do
        token = user.email_tokens.find_by(email: user.email)
        EmailToken.confirm(token.token)
      end

      it 'logs in' do
        events = DiscourseEvent.track_events do
          post :create, params: {
            login: user.username, password: 'myawesomepassword'
          }, format: :json
        end

        expect(response.status).to eq(200)
        expect(events.map { |event| event[:event_name] }).to contain_exactly(
          :user_logged_in, :user_first_logged_in
        )

        user.reload

        expect(session[:current_user_id]).to eq(user.id)
        expect(user.user_auth_tokens.count).to eq(1)
        expect(UserAuthToken.hash_token(cookies[:_t])).to eq(user.user_auth_tokens.first.auth_token)
      end

      context 'when user is linked to VivoKey' do
        before do
          UserAssociatedAccount.create!(
            user: user,
            provider_name: 'vivokey',
            provider_uid: 'uid'
          )
        end

        it 'does not log in' do
          events = DiscourseEvent.track_events do
            post :create, params: {
              login: user.username, password: 'myawesomepassword'
            }, format: :json
          end

          expect(session[:current_user_id]).to be_nil

          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)['error']).to eq(
            "You must log in using your VivoKey."
          )
        end
      end
    end
  end
end
