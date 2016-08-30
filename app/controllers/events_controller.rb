class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :feed, :show, :levels]
  before_action :find_event, except: [:index, :feed, :create, :new]
  before_action :validate_organizer!, except: [:index, :feed, :create, :show, :new, :levels]
  before_action :set_time_zone, only: [:create, :update]

  def index
    respond_to do |format|
      format.html do
        @events = Event.upcoming.published_or_organized_by(current_user).includes(:event_sessions, :location, :region)
        @event_regions = @events.map { |e| e.region }.compact.uniq
        @past_events = EventList.new('past').combined_events
      end
      format.json do
        render json: EventList.new(params[:type])
      end
    end
  end

  def feed
    @events = Event.upcoming.published_or_organized_by(current_user).includes(:event_sessions, :location, :region)

    respond_to do |format|
      format.rss {render 'events/feed.rss.builder', layout: false}
      format.atom {render 'events/feed.atom.builder', layout: false}
    end
  end

  def show
    if user_signed_in? && !@event.historical?
      @organizer = @event.organizer?(current_user) || current_user.admin?
      @checkiner = @event.checkiner?(current_user)
    else
      @organizer = false
      @checkiner = false
    end
    @ordered_rsvps = {
      Role::VOLUNTEER => @event.ordered_rsvps(Role::VOLUNTEER),
      Role::STUDENT => @event.ordered_rsvps(Role::STUDENT)
    }
    @ordered_waitlist_rsvps = {
      Role::VOLUNTEER => @event.ordered_rsvps(Role::VOLUNTEER, waitlisted: true).to_a,
      Role::STUDENT => @event.ordered_rsvps(Role::STUDENT, waitlisted: true).to_a
    }
  end

  def new
    @event = Event.new(public_email: current_user.email, time_zone: current_user.time_zone, location_id: params[:location_id])
    @event.event_sessions << EventSession.new
  end

  def edit
  end

  def create
    result = EventEditor.new(current_user, params).create
    @event = result[:event]

    flash[:notice] = result[:notice] if result[:notice]
    if result[:render]
      render result[:render]
    else
      redirect_to result[:event]
    end
  end

  def update
    result = EventEditor.new(current_user, params).update(@event)

    flash[:notice] = result[:notice] if result[:notice]
    if result[:render]
      render result[:render], status: result[:status]
    else
      redirect_to @event
    end
  end

  def destroy
    @event.destroy
    redirect_to events_url
  end

  protected

  def set_time_zone
    if params[:event] && params[:event][:time_zone].present?
      Time.zone = params[:event][:time_zone]
    end
  end

  def find_event
    @event = Event.find(params[:id])
  end

  def allow_insecure?
    request.get? && request.format.json?
  end
end
