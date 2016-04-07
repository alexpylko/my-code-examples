require 'action_dispatch/routing/mapper'

module ActionDispatch::Routing::Mapper::Resources
  alias_method :resources_without_features, :resources

  class Resource

    RESOURCE_ACTIONS = [:restore, :search]

    alias_method :default_actions_without_features, :default_actions

    def default_actions
      default_actions_without_features.concat(RESOURCE_ACTIONS)
    end

  end

  def resources(*resources, &block)
    resources_without_features *resources do
      collection do
        if parent_resource.actions.include?(:search)
          get 'search/:q', to: "#{@scope[:controller]}#search"
          get :search
        end
      end
      member do
        put :restore if parent_resource.actions.include?(:restore)
      end
      yield if block_given?
    end
  end

end