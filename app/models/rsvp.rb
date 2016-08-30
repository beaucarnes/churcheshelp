class Rsvp < ActiveRecord::Base
  PERMITTED_ATTRIBUTES = [:subject_experience, :teaching, :taing, :teaching_experience, :teaching_experience, :childcare_info, :operating_system_id, :job_details, :class_level, :dietary_info, :needs_childcare, :plus_one_host]

  belongs_to :bridgetroll_user, class_name: 'User', foreign_key: :user_id
  belongs_to :meetup_user, class_name: 'MeetupUser', foreign_key: :user_id
  belongs_to :user, polymorphic: true
  belongs_to :event, inverse_of: :rsvps
  belongs_to :section

  delegate :full_name, to: :user
  delegate :historical?, to: :event, allow_nil: true

  has_many :rsvp_sessions, dependent: :destroy
  has_many :event_sessions, through: :rsvp_sessions
  has_many :dietary_restrictions, dependent: :destroy
  has_many :event_email_recipients, foreign_key: :recipient_rsvp_id, dependent: :destroy

  has_one  :survey, dependent: :destroy

  validates_uniqueness_of :user_id, scope: [:event_id, :user_type]
  validates_presence_of :user, :event, :role
  validates_presence_of :childcare_info, if: :needs_childcare?

  scope :confirmed, -> { where("waitlist_position IS NULL") }
  scope :needs_childcare, -> { where("childcare_info <> ''") }

  after_initialize :set_defaults

  after_save :update_counter_cache
  after_destroy :update_counter_cache

  MAX_EXPERIENCE_LENGTH = 100
  
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :role
  belongs_to_active_hash :volunteer_assignment
  belongs_to_active_hash :operating_system
  belongs_to_active_hash :volunteer_preference

  def set_defaults
    if has_attribute?(:token)
      self.token ||= SecureRandom.uuid.gsub(/\-/, '')
    end
  end

  # Dispatch to the two possible types of user, the modern kind (User) or imports
  # from meetup (MeetupUser). This is mostly important for weird eager loading
  # situations like Event#ordered_rsvps
  #
  # Ideally eager loading would work better for polymorphic associations, so the
  # regular 'user' association could be used instead of this. But it doesn't!
  # This can probably be removed if this Rails PR ever gets accepted:
  # https://github.com/rails/rails/pull/17479
  def loaded_user
    user_type == 'MeetupUser' ? meetup_user : bridgetroll_user
  end

  def setup_for_role(role)
    self.role = role
    if role == Role::VOLUNTEER
      self.event_session_ids = event.event_sessions.pluck(:id)
    elsif role == Role::STUDENT
      self.event_session_ids = event.event_sessions.where(required_for_students: true).pluck(:id)
    end

    return unless user

    prior_rsvps = user.rsvps.includes(:event).order('events.ends_at')

    last_rsvp = prior_rsvps.where('events.course_id = ?', event.course_id).last || prior_rsvps.last
    if last_rsvp
      assign_attributes(last_rsvp.carryover_attributes(event.course_id, role))
    end
  end

  def selectable_sessions
    sessions = event.event_sessions.order('starts_at ASC')
    if role == Role::VOLUNTEER
      sessions
    elsif role == Role::STUDENT
      sessions.where(volunteers_only: false)
    else
      raise "No selectable_sessions for Role::#{role.name}"
    end
  end

  def operating_system_title
    operating_system.try(:title)
  end

  def operating_system_type
    operating_system.try(:type)
  end

  def full_dietary_info
    restrictions = dietary_restrictions.map { |dr| dr.restriction.capitalize }
    restrictions << dietary_info if dietary_info.present?
    restrictions.join(', ')
  end

  def no_show?
    return false if event.historical?
    return false if event.upcoming?

    checkins_count == 0
  end

  def checked_in_session_ids
    if role == Role::ORGANIZER
      event.event_sessions.map(&:id)
    else
      rsvp_sessions.where(checked_in: true).pluck(:event_session_id)
    end
  end

  def role_volunteer?
    role == Role::VOLUNTEER
  end

  def role_student?
    role == Role::STUDENT
  end

  def teaching_or_taing?
    teaching || taing
  end

  def requires_session_rsvp?
    return false if role == Role::ORGANIZER
    event.try(:upcoming?)
  end

  def volunteer_preference_id
    return unless role_volunteer?

    return VolunteerPreference::BOTH.id    if teaching && taing
    return VolunteerPreference::TEACHER.id if teaching
    return VolunteerPreference::TA.id      if taing
    VolunteerPreference::NEITHER.id
  end

  def carryover_attributes(new_event_course_id, role)
    fields = [:job_details]

    if role == Role::VOLUNTEER && event.course_id == new_event_course_id
      fields += [:subject_experience, :teaching_experience]
    end

    fields.each_with_object({}) do |field, hsh|
      hsh[field] = send(field)
    end
  end

  def formatted_preference
    volunteer_preference.title
  end

  def waitlisted?
    !!waitlist_position
  end

  def needs_childcare?
    @needs_childcare = childcare_info.present? if @needs_childcare.nil?
    @needs_childcare
  end

  alias_method :needs_childcare, :needs_childcare?

  def needs_childcare= needs_childcare
    needs_childcare = needs_childcare == '1' if needs_childcare.is_a? String

    @needs_childcare = needs_childcare
    self.childcare_info = nil unless needs_childcare
    needs_childcare
  end

  before_save do
    unless needs_childcare?
      self.childcare_info = nil
    end
  end

  def self.attendances_for(user_type)
    # TODO: This fetches one row for each user+role combo that exists in the system.
    # This may someday be too much to fit in memory, but find_each doesn't work
    # because it wants to order by rsvps.id, which defeats the purpose of a 'group_by'
    # Consider reworking to either just iterate over all RSVPs (without group_by)
    # or somehow construct one mecha-query that fetches user information as well
    # as their student/volunteer/organizer attendance count.
    attendances = {}
    Rsvp.where(user_type: user_type).select('user_id, role_id, count(*) count').group('role_id, user_id').each do |rsvp_group|
      attendances[rsvp_group.user_id] ||= Role.empty_attendance.clone
      attendances[rsvp_group.user_id][rsvp_group.role_id] = rsvp_group.count.to_i
    end

    attendances
  end

  def update_counter_cache
    event.update_rsvp_counts if event
  end

  def as_json(options={})
    options[:methods] ||= []
    options[:methods] |= [:full_name, :operating_system_title, :operating_system_type]
    super(options)
  end
end
