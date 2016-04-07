module Bitfit
  module RestoreResources
    extend ActiveSupport::Concern

    included do
      before_filter :load_deleted_resource, only: [:restore]
    end

    def restore
      resource.restore
      show!
    end

    def load_deleted_resource
      set_resource_ivar(end_of_association_chain.deleted.find(params[:id]))
    end

  end
end

class ActionController::Base

  def self.restore_resources
    include Bitfit::RestoreResources
  end

end
