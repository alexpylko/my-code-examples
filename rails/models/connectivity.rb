class Customer::Connectivity < Customer::Network
  include Bitfit::Customer::Connectivity::Base
  include Bitfit::Customer::Connectivity::Summary
  include Bitfit::Customer::Connectivity::Searchable
  include Bitfit::ActAsAttachment
  include Bitfit::History
  include Bitfit::Profile

  POINT_TO_POINT_VALUE = 'Point-to-Point'
  DARK_FIBER_VALUE = 'Dark Fiber'

  belongs_to :customer, inverse_of: :connectivities

  track_monthly_history class_name: 'Customer::History::Connectivity',
    as: :history_connectivities,
    param_name: :network_id

  act_as_attachment

  alias_method :history_networks, :history_connectivities

  protected

  before_save :update_z_site, if: :connectivity_type_changed?
  before_save :update_effective_cost, if: :effective_cost_changed?

  def reset_site_z
    self.site_z_name = ''
    self.site_z_location = ''
    self.site_z_vendor = ''
    self.site_z_type = ''
  end

  def update_z_site
    reset_site_z unless connectivity_type == POINT_TO_POINT_VALUE || connectivity_type == DARK_FIBER_VALUE
  end

  def effective_cost_changed?
    peak_rate_changed? or current_month_cost_changed?
  end

  def update_effective_cost
    self.effective_cost = current_month_cost.to_f / peak_rate
  rescue
    self.effective_cost = 0
  end
end
