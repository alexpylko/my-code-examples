class Customer::Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::MagicCounterCache
  include Mongoid::Alize
  include Bitfit::Paranoia
  include Bitfit::ActAsDictionary
  include ES::Searchable
  include Extra
  include Mongoid::Delorean::Trackable
  include Bitfit::ActAsAttachment
  include Bitfit::ActAsAggregatable

  store_in collection: 'customers_invoices'

  default_scope desc(:tracked_at)

  field :nm, as: :name, type: String
  field :tmc, as: :total_mrc, type: Money, default: Money.new(0)
  field :tnc, as: :total_nrc, type: Money, default: Money.new(0)
  field :tcs, as: :total_cost, type: Money, default: Money.new(0)

  field :tat, as: :tracked_at, type: Date
  field :last_invoice_id, type: Moped::BSON::ObjectId

  validates :name, presence: true, month_uniqueness: { scope: :customer_id, month: :tracked_at, unless: :tracked_at_nil? }, allow_nil: true
  validates :customer, presence: true

  act_as_dictionaries :vendor, :account
  act_as_dictionary :status, collection: ::Dictionary, name: :invoice_status

  attr_accessible :name,
                  :date,
                  :vendor,
                  :account,
                  :status,
                  :tracked_at

  slug :name, scope: :vendor

  index({ name: 1 }, { background: true })
  index({ name: 1, customer_id: 1, tracked_at: 1 }, { background: true })
  index({'vendor.name' => 1, tracked_at: 1, name: 1}, { background: true })

  has_one :last_invoice,
          class_name: 'Customer::Invoice', 
          foreign_key: :last_invoice_id

  belongs_to :next_invoice,
          class_name: 'Customer::Invoice', 
          foreign_key: :last_invoice_id        

  has_many :entries,
           class_name: 'Customer::InvoiceEntry',
           dependent: :destroy,
           inverse_of: :invoice,
           extend: Bitfit::ES::SearchExtension

  alize_to :entries, :vendor, :tracked_at

  belongs_to :customer, inverse_of: :invoices

  counter_cache :customer

  act_as_attachment

  def tracked_at_nil?
    tracked_at.nil? 
  end

  def csv_fields
    %i(name vendor account status tracked_at total_cost)
  end

  def dictionaries_collection
    customer.dictionaries
  end
end