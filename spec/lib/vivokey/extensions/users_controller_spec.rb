require 'rails_helper'

describe UsersController, type: :controller do
  let(:user) { Fabricate(:user) }

  describe '#create' do
    def honeypot_magic(params)
      get '/u/hp.json'
      json = JSON.parse(response.body)
      params[:password_confirmation] = json["value"]
      params[:challenge] = json["challenge"].reverse
      params
    end

    before do
      UsersController.any_instance.stubs(:honeypot_value).returns(nil)
      UsersController.any_instance.stubs(:challenge_value).returns(nil)
      SiteSetting.allow_new_registrations = true
      @user = Fabricate.build(:user, password: "strongpassword")
    end

    let(:post_user_params) do
      { name: @user.name,
        username: @user.username,
        password: "strongpassword",
        email: @user.email }
    end

    def post_user
      post "/u.json", params: post_user_params
    end

    context "when 'invite only' setting is enabled" do
      before { SiteSetting.invite_only = true }

      let(:create_params) { {
        name: @user.name,
        username: @user.username,
        password: 'strongpassword',
        email: @user.email
      }}

      context 'when user is not linked to VivoKey' do
        before do
          described_class.any_instance.stubs(:vivokey?).returns(false)
        end

        it 'should not create a new user' do
          expect {
            post :create, params: create_params, format: :json
          }.to_not change { User.count }

          expect(response.status).to eq(200)
        end

        it 'should not send an email' do
          User.any_instance.expects(:enqueue_welcome_message).never
          post :create, params: create_params, format: :json
          expect(response.status).to eq(200)
        end

        it 'should say it was successful' do
          post :create, params: create_params, format: :json
          json = JSON::parse(response.body)
          expect(response.status).to eq(200)
          expect(json["success"]).to eq(true)

          # should not change the session
          expect(session["user_created_message"]).to be_blank
          expect(session[SessionController::ACTIVATE_USER_KEY]).to be_blank
        end
      end

      context 'when user is linked to VivoKey' do
        before do
          described_class.any_instance.stubs(:vivokey?).returns(true)
        end

        it 'should create a new user' do
          expect {
            post :create, params: create_params, format: :json
          }.to change { User.count }.by(1)

          expect(response.status).to eq(200)
        end

        it 'should say it was successful' do
          post :create, params: create_params, format: :json
          json = JSON::parse(response.body)
          expect(response.status).to eq(200)
          expect(json["success"]).to eq(true)

          expect(session["user_created_message"]).not_to be_blank
          expect(session[SessionController::ACTIVATE_USER_KEY]).not_to be_blank
        end
      end
    end
  end
end
