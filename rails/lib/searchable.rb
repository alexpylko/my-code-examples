module Bitfit
  module Controllers
    module Searchable
      extend ActiveSupport::Concern

      included do
        before_filter :search_collection, only: :search
      end

      # search Restful action
      def search(options={}, &block)
        respond_with(*with_chain(search_collection), options, &block)
      end

      # groups by model ids
      def group_ids
        @group_ids ||= current_user.group_ids
      end

      protected

      def search_collection
        get_collection_ivar || set_collection_ivar(end_of_association_chain.search(search_params))
      end

      def search_params
        parameters = respond_to?(:permitted_params, true) ? permitted_params : params

        history_meta = Bitfit::History.tracked_models.select{|e| e[:class_name] == resource_class.to_s}.first
        if history_meta
          name = (history_meta[:param_name] || "#{history_meta[:name]}_id").to_sym
          parameters.merge!(name => params[name]) if params[name]
        end

        if group_ids.empty? 
          parameters.reverse_merge(default_params)
        else
          parameters.reverse_merge(default_params).merge(group_ids: group_ids)
        end
      end
    end
  end
end