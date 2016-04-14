module Bitfit
  module Exceptions
    extend ActiveSupport::Concern

    included do
      rescue_from CanCan::AccessDenied, with: :forbidden
      rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found
      rescue_from Bitfit::Errors::NotFound, with: :not_found
    end

    private

    def forbidden(exception)
      error(exception, :forbidden)
    end

    def not_found(exception)
      error(exception, :not_found)
    end

    def error(exception, status)
      respond_to do |format|
        format.html { redirect_to root_url, :alert => exception.message }
        format.json { render :json => {:errors => [exception.message]}, :status => status }
      end
    end

  end
end
