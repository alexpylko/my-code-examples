module Api

  class ApiController < ActionController::Metal

    # rails stack
    include ActionController::Helpers
    include ActionController::Redirecting
    include ActionController::Rendering
    include ActionController::Renderers::All
    include ActionController::ConditionalGet
    include ActionController::MimeResponds
    include ActionController::ForceSSL
    include AbstractController::Callbacks
    include ActionController::Rescue
    include ActionController::Instrumentation
    include ActionController::ParamsWrapper
    include ActionController::QueryParamsWrapper
    include ActionController::DataStreaming
    include ActionController::StrongParameters
    include Browser::ActionController

    # devise
    include Devise::Controllers::Helpers

    # cancan
    include CanCan::ControllerAdditions

    # airbrake
    #if defined?(Airbrake::Rails::ControllerMethods)
    #  include Airbrake::Rails::ControllerMethods
    #end

    # rollbar
    if defined?(Rollbar::Rails::ControllerMethods)
      include Rollbar::Rails::ControllerMethods
    end

    # restore resources
    include Bitfit::RestoreResources

    # include exceptions handling
    include Bitfit::Exceptions

    # authenticate user via Devise
    before_filter :authenticate_user!

    if Rails.env.staging?
      before_filter :set_access_control_headers
    end

    if defined?(Mongoid::Userstamp)
      # initialize Mongoid::Userstamp manually
      before_filter do |c|
        begin
          Mongoid::Userstamp.config.user_model.current = c.send(Mongoid::Userstamp.config.user_reader)
        rescue
        end
      end
    end

    helper_method :current_user

    def current_ability
      current_user.ability
    end

    # set path to views
    append_view_path "#{Rails.root}/app/views"

    respond_to :json

    wrap_parameters format: [:json]
    wrap_query_parameters format: [:json]

    def routing_error
      raise Bitfit::Errors::NotFound
    end

    def set_access_control_headers
      headers['Access-Control-Allow-Origin'] = "http://staging.bitfit.com, https://staging.bitfit.com"
    end
  end

end
