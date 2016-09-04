class Ministry < ActiveRecord::Base
  PERMITTED_ATTRIBUTES = [:title, :location_id, :details, :when, :email_on_approval, :current_state, :spam]

  belongs_to :location #, counter_cache: true
  validates :location_id, presence: true
  validates_presence_of :title
  has_one :region, through: :location

  enum current_state: [ :draft, :pending_approval, :published ]
  validates :current_state, inclusion: { in: Event.current_states.keys }

  def location_name
    location ? location.name : ''
  end

  def location_city_and_state
    "#{location.city}, #{location.state}"
  end

  def to_linkable
    self
  end

  def organizer?(user)
    user.location_id == self.location_id && user.location_admin
  end

  def self.published_or_organized_by(user = nil)
    return self.published unless user
 
    if user.admin?
      where(spam: false)
    else
      if user.location_admin

        return where('location_id = ? OR (current_state = ?)', user.location_id, Event.current_states[:published])

      else
        return self.published
        
      end
    end
  end
end
