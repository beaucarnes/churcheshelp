class Location < ActiveRecord::Base
  PERMITTED_ATTRIBUTES = [:name, :address_1, :address_2, :city, :state, :zip, :region_id]

  scope :available, -> { where(archived_at: nil) }
  has_many :events, -> { published }
  has_many :ministries #, -> { published }
  belongs_to :region, counter_cache: true

  validates_presence_of :name, :address_1, :city, :region
  unless Rails.env.test?
    geocoded_by :full_address
    after_validation :geocode
  end

  def full_address
    "#{self.address_1}, #{self.city}, #{self.state}, #{self.zip}"
  end

  def name_with_region
    "#{name} (#{region.name})"
  end

  def editable_by?(user)
    return true if events_count == 0
    return true if user.admin?
    notable_events.map { |e| e.organizers }.flatten.map(&:id).include?(user.id)
  end

  def additional_details_editable_by?(user)
    region && region.has_leader?(user)
  end

  def archivable_by?(user)
    return false unless persisted?
    return false if archived?
    editable_by?(user) || additional_details_editable_by?(user)
  end

  def organized_event?(user)
    notable_events.map { |e| e.organizer?(user) }.include?(true)
  end

  def notable_events
    if events.present?
      events
    else
      Event.where(location_id: id).where(current_state: Event.current_states.values_at(:draft, :pending_approval))
    end
  end

  def archive!
    update_columns(archived_at: DateTime.now)
  end

  def archived?
    archived_at.present?
  end

  def as_json(options = {})
    {
      name: name,
      address_1: address_1,
      address_2: address_2,
      city: city,
      state: state,
      zip: zip,
      latitude: latitude,
      longitude: longitude,
    }
  end
end
