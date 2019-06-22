# frozen_string_literal: true

require 'rails_helper'
require_relative '../../lib/vivo_key_authenticator'

describe VivoKeyAuthenticator do
  describe '#after_authenticate' do
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
  end
end
