class Section < ActiveRecord::Base
  PERMITTED_ATTRIBUTES = [:name, :class_level]

  belongs_to :event
  has_many :rsvps, dependent: :nullify

  def student_rsvps
    rsvps.where(role_id: Role::STUDENT.id)
  end

  def volunteer_rsvps
    rsvps.where(role_id: Role::VOLUNTEER.id)
  end
end
