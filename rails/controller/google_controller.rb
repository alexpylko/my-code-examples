class Api::V2::GoogleController < Api::ApiController
  include Bitfit::Auth::Google
  include Bitfit::Controllers::MobileAuthHelper

  skip_before_filter :authenticate_user!

  def create
    @current_user = @user = authenticate(raw_info)
    resource = warden.authenticate!(scope: :user)
    sign_in(:user, @user)
  end

  def callback
    create
    if @current_user
      render :js => "window.location = '#{mobile_root(@current_user)}'"
    end
  end

  def mobile_root user
    "/app3/#{user.customer.slug}"
  end

  def failure
    Rails.logger.debug(env["omniauth.error"].inspect)
  end

  protected

  def raw_info
    @raw_info ||= access_token.get('https://www.googleapis.com/plus/v1/people/me/openIdConnect').parsed
  end

  def access_token
    @access_token ||= oauth2_client.auth_code.get_token(params['code'], deep_symbolize(token_params))
  end

  def token_params
    google_options[:options]
  end

  def oauth2_client
    ::OAuth2::Client.new(google_options[:client_id], google_options[:client_secret], deep_symbolize(client_options))
  end

  def client_options
    {
      :site          => 'https://accounts.google.com',
      :authorize_url => '/o/oauth2/auth',
      :token_url     => '/o/oauth2/token'
    }
  end

  def deep_symbolize(options)
    hash = {}
    options.each do |key, value|
      hash[key.to_sym] = value.is_a?(Hash) ? deep_symbolize(value) : value
    end
    hash
  end

  protected

  def www_app?
    request.headers['MOBILE_APP'].present? ? false : request.headers['WEB_APP'].present?
  end

  def google_auth_env
    www_app? ? :web : :mobile
  end

  def google_options
    @_google_options ||= Rails.configuration.google_oauth2[google_auth_env]
  end

end