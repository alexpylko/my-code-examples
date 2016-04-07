require 'spec_helper'

describe SamlController do
  let(:one_login_resp) { double("resp") }

  context '#consume' do
    before(:each) do
      allow(OneLogin::RubySaml::Response).to receive(:new) { one_login_resp }

      post :consume
    end

    context 'simple success authorization' do
      let(:customer) { create(:customer) }

      before do
        allow(Customer).to receive(:find_by) { customer }
        allow(OneLogin::RubySaml::Response).to receive(:new) { one_login_resp }
      end

      describe 'existing user' do
        let(:user) { create(:user, customer_id: customer.id) }
        let(:one_login_resp) { double("resp", is_valid?: true, issuer: 'test', name_id: user.email, 'settings=' => nil, attributes: {}) }

        before(:each) do
          post :consume
        end

        it { expect(response).to redirect_to(user.homepage) }
        it { expect(subject.current_user).to_not be nil }
      end

      describe 'new user' do
        let(:one_login_resp) { double("resp", is_valid?: true, issuer: nil, name_id: Faker::Internet.email, 'settings=' => nil, 
          attributes: {"User.email" => Faker::Internet.email, "User.FirstName" => Faker::Lorem.word,"User.LastName" => Faker::Lorem.word}) }

        before(:each) do
          post :consume
        end

        it { expect(response).to redirect_to(User.last.homepage) }
        it { expect(subject.current_user).to_not be nil }
      end

      context 'with cookies params(include_token && return_to)' do
        let(:user) { create(:user, customer_id: customer.id) }
        let(:one_login_resp) { double("resp", is_valid?: true, issuer: 'test', name_id: user.email, 'settings=' => nil, attributes: {}) }

        describe 'return_to' do
          before(:each) do
            @request.cookies[:return_to] = "http://test.com"

            post :consume
          end

          it { expect(response).to redirect_to("http://test.com") }
          it { expect(subject.current_user).to_not be nil }
        end

        describe 'return_to && include_token' do
          before(:each) do
            @request.cookies[:return_to] = "http://test.com"
            @request.cookies[:include_token] = true

            post :consume
          end

          it { expect(response).to redirect_to("http://test.com?token=#{user.auth_token}") }
          it { expect(subject.current_user).to_not be nil }
        end
      end
    end

    context 'authorization fails' do
      describe 'responce is not valid' do
        let(:one_login_resp) { double("resp", is_valid?: false, issuer: '', 'settings=' => nil) }

        it { expect(response).to redirect_to('/') }
        it { expect(subject.current_user).to be nil }
      end

      describe 'issuer is nil' do
        let(:one_login_resp) { double("resp", is_valid?: true, issuer: nil, 'settings=' => nil) }

        it { expect(response).to redirect_to('/') }
        it { expect(subject.current_user).to be nil }
      end
    end
  end
end