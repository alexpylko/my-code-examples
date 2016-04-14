require 'spec_helper'

describe ApplicationController do
  context "#after_sign_in_path_for" do
    let(:user) { create(:user) }

    describe 'normal login' do
      before(:each) do
        sign_in user
      end

      it { expect(controller.after_sign_in_path_for(user)).to eq user.homepage }
    end

    describe 'mobile login' do
      context "mobile_homepage present" do
        before(:each) do
          allow(controller).to receive(:mobile?) { true }

          sign_in user
        end

        it { expect(controller.after_sign_in_path_for(user)).to eq user.mobile_homepage }
      end

      context "mobile_homepage missing" do
        let(:customer) { create(:customer) }
        let(:user) { create(:user, mobile_homepage: nil, customer: customer) }

        before(:each) do
          ENV['MOBILE_HOST'] = "testhost:1"
          allow(controller).to receive(:mobile?) { true }

          sign_in user
        end

        it { expect(controller.after_sign_in_path_for(user)).to eq "testhost:1/app3/#{customer.slug}#device/dashboard" }
      end
    end

    describe 'with extra cookies params' do
      context "return_to" do
        before(:each) do
          @request.cookies[:return_to] = "http://test.com"

          sign_in user
        end

        it { expect(controller.after_sign_in_path_for(user)).to eq "http://test.com" }
      end

      context "include_token" do
        before(:each) do
          @request.cookies[:return_to] = "http://test.com"
          @request.cookies[:include_token] = true

          sign_in user
        end

        it { expect(controller.after_sign_in_path_for(user)).to eq "http://test.com?token=#{user.auth_token}" }
      end
    end
  end
end