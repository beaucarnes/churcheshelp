class Events::UnpublishedEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_publisher!
  before_action :find_event, except: [:index]

  def index
    regions = Region.includes(:users)
                 .where('users.allow_event_email = ?', true)
                 .references(:users)
    @region_user_counts = regions.each_with_object({}) do |region, hsh|
      hsh[region.id] = region.users.length
    end
    @events = Event.upcoming.pending_approval.where(spam: false)
    @ministries = Ministry.pending_approval.where(spam: false)

  end

  def publish
    @event.update_attributes(current_state: :published)
    if @event.email_on_approval
      EventMailer.new_event(@event).deliver_now 
      @event.update_attribute(:announcement_email_sent_at, DateTime.now) unless params[:ministry]
    end
    redirect_to @event, notice: "This event has been published. Now everyone in the world can see it!"
  end

  def flag
    @event.update_attribute(:spam, true)
    @event.organizers.first.update_attribute(:spammer, true)
    redirect_to unpublished_events_path, notice: "#{@event.title} has been flagged as spam, and #{@event.organizers.first.full_name} has been flagged as a spammer so any other events they create will immediately be flagged as spam."
  end

  private

  def find_event

    @event = params[:ministry] ? Ministry.find(params[:unpublished_event_id]) : Event.find(params[:unpublished_event_id])
  end
end