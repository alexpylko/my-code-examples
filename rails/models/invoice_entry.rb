class Customer::InvoiceEntry
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Mongoid::MagicCounterCache
  include Mongoid::Alize
  include Bitfit::Paranoia
  include Bitfit::ActAsDictionary
  include ES::Searchable
  include Extra
  include Bitfit::ActAsAggregatable

  field :customer_id, type: Moped::BSON::ObjectId
  field :tat, as: :tracked_at, type: Date
  
  act_as_dictionary :product_type, collection: ::Dictionary, name: :invoice_product_type
  act_as_dictionary :product_name, validates: { presence: true, uniqueness: true }
  act_as_dictionaries :site_a, :site_z

  validates :invoice, presence: true

  attr_accessible :product_name,
                  :product_type,
                  :billing_start_at,
                  :billing_end_at,
                  :units,
                  :unit_mrc,
                  :total_mrc,
                  :unit_nrc,
                  :total_nrc,
                  :discount,
                  :site_a,
                  :site_z,
                  :tracked_at
                  
  def vendor_name
    invoice.vendor if invoice
  end

  belongs_to :invoice, class_name: 'Customer::Invoice', inverse_of: :entries
  belongs_to :customer, inverse_of: :invoices_entries
  belongs_to :product, class_name: 'Customer::Product', inverse_of: :invoice_entries

  alize_from :invoice, :vendor# :tracked_at

  counter_cache :invoice

  protected

  def dictionaries_collection
    (customer || invoice.customer).dictionaries
  end
end