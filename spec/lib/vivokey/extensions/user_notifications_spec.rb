require 'rails_helper'

describe UserNotifications do
  let(:user) { Fabricate(:admin) }

  describe '.forgot_password' do
    subject { UserNotifications.forgot_password(user, email_token: 'token') }

    context 'when user has password' do
      it 'sends password reset link' do
        expect(subject.to).to eq([user.email])
        expect(subject.subject).to eq '[Discourse] Password reset'
        expect(subject.from).to eq([SiteSetting.notification_email])
        expect(subject.body).to include('token')
      end
    end

    context 'when user does not have a password' do
      let(:user) { Fabricate(:admin, password: nil) }

      it 'sends password set link' do
        expect(subject.to).to eq([user.email])
        expect(subject.subject).to eq '[Discourse] Set Password'
        expect(subject.from).to eq([SiteSetting.notification_email])
        expect(subject.body).to include('token')
      end
    end

    context 'when user is linked to VivoKey' do
      before do
        UserAssociatedAccount.create!(
          user: user,
          provider_name: 'vivokey',
          provider_uid: 'uid'
        )
      end

      context 'when user has password' do
        it 'sends "You must log in using your VivoKey."' do
          expect(subject.to).to eq([user.email])
          expect(subject.subject).to eq '[Discourse] Password reset'
          expect(subject.from).to eq([SiteSetting.notification_email])

          expect(subject.body).not_to include('token')
          expect(subject.body).to include('You must log in using your VivoKey.')
        end
      end

      context 'when user does not have a password' do
        let(:user) { Fabricate(:admin, password: nil) }

        it 'sends "You must log in using your VivoKey."' do
          expect(subject.to).to eq([user.email])
          expect(subject.subject).to eq '[Discourse] Set Password'
          expect(subject.from).to eq([SiteSetting.notification_email])

          expect(subject.body).not_to include('token')
          expect(subject.body).to include('You must log in using your VivoKey.')
        end
      end
    end
  end

  describe '.email_login' do
    subject { UserNotifications.email_login(user, email_token: 'token') }

    it 'sends login link' do
      expect(subject.to).to eq([user.email])
      expect(subject.subject).to eq '[Discourse] Log in via link'
      expect(subject.from).to eq([SiteSetting.notification_email])
      expect(subject.body).to include('token')
    end

    context 'when user is linked to VivoKey' do
      before do
        UserAssociatedAccount.create!(
          user: user,
          provider_name: 'vivokey',
          provider_uid: 'uid'
        )
      end

      it 'sends "You must log in using your VivoKey."' do
        expect(subject.to).to eq([user.email])
        expect(subject.subject).to eq '[Discourse] Log in via link'
        expect(subject.from).to eq([SiteSetting.notification_email])

        expect(subject.body).not_to include('token')
        expect(subject.body).to include('You must log in using your VivoKey.')
      end
    end
  end
end
