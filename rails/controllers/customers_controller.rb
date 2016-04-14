module Api
  #
  # = Customers
  #
  #    $ curl -v -X GET http://localhost:3000/api/customers?auth_token=FsZi7ppz7xmSA6jCyu2t -H "Content-Type: application/json"
  #
  #    $ curl -v -X POST --data '{"customer":{"name":"Client","slug":"cln"}}' http://localhost:3000/api/customers?auth_token=FsZi7ppz7xmSA6jCyu2t -H "Content-Type: application/json"
  #
  #    $ curl -v -X PUT --data '{"customer":{"slug":"cln-new"}}' http://localhost:3000/api/customers/cln?auth_token=FsZi7ppz7xmSA6jCyu2t -H "Content-Type: application/json"
  #
  class CustomersController < Api::ApiController
    authorize_resource
    inherit_resources
    restore_resources
    wrap_parameters :customer

    protected

    def permitted_params
      params.permit(customer: [:name, :slug])
    end
  end
end