# frozen_string_literal: true

require 'rails_helper'
require_relative '../../lib/vivo_key_authenticator'

describe VivoKeyAuthenticator do
  let(:auth_result) { described_class.new.after_authenticate(auth_token) }

  let(:auth_token) do
    {
      provider: 'vivokey',
      uid: '1234',
      info: {
        email: 'awesome@example.com'
      },
      extra: {
        raw_info: {
          email_verified: true
        }
      }
    }
  end

  describe 'marking email as valid' do
    context 'when email is verified' do
      it { expect(auth_result.email_valid).to be true }
    end

    context 'when email is not verified' do
      before { auth_token[:extra][:raw_info][:email_verified] = false }
      it { expect(auth_result.email_valid).to be_falsey }
    end

    context 'when email verification status is unknown' do
      before { auth_token[:extra][:raw_info] = {} }
      it { expect(auth_result.email_valid).to be_falsey }
    end

    context 'when there is no email' do
      before do
        auth_token[:info][:email] = nil
        auth_token[:extra][:raw_info] = {}
      end

      it { expect(auth_result.email_valid).to be_falsey }
    end
  end

  describe 'account registration' do
    before { SiteSetting.vivokey_openid_registration = false }

    context 'when account registration is allowed' do
      before { SiteSetting.vivokey_openid_registration = true }
      it { expect(auth_result).not_to be_failed }
    end

    context 'when account registration is not allowed' do
      it { expect(auth_result).to be_failed }
      it { expect(auth_result.failed_reason).to eq 'Account registration via VivoKey OpenID is not allowed.' }
    end

    context 'when account registration is not needed' do
      before do
        user = Fabricate(:user, email: auth_token.dig(:info, :email))
        UserAssociatedAccount.create!(user: user, provider_name: auth_token[:provider], provider_uid: auth_token[:uid])
      end
      it { expect(auth_result).not_to be_failed }
    end
  end

  it 'matching by email is disabled' do
    Fabricate(:user, email: auth_token.dig(:info, :email))
    expect(auth_result.user).to be_nil
    expect(auth_result.email_valid).to be false
  end

  it 'but connecting existing account is not' do
    SiteSetting.vivokey_openid_allow_association_change = true
    user = Fabricate(:user, email: auth_token.dig(:info, :email))

    auth_result = described_class.new.after_authenticate(auth_token, existing_account: user)

    expect(auth_result.user).to eq user
  end
end
