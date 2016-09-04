class MinistriesController < ApplicationController
  before_action :find_ministry, except: [:index, :feed, :create, :new]

  def index
    
    respond_to do |format|
      format.html do
        @ministries = Ministry.published_or_organized_by(current_user)
        @ministry_regions = @ministries.map { |e| e.region }.compact.uniq
      end
      format.json do
        render json: EventList.new(params[:type])
      end
    end
  end

  def new
    @ministry = Ministry.new(location_id: params[:location_id])
    
  end

  def edit
  end

  def show
    if user_signed_in?
      @organizer = @ministry.organizer?(current_user) || current_user.admin?
    else
      @organizer = false
      @checkiner = false
    end

  end

  def create
    result = MinistryEditor.new(current_user, params).create
    @ministry = result[:ministry]

    flash[:notice] = result[:notice] if result[:notice]
    if result[:render]
      render result[:render]
    else
      redirect_to result[:ministry]
    end
  end

  def update
    result = MinistryEditor.new(current_user, params).update(@ministry)

    flash[:notice] = result[:notice] if result[:notice]
    if result[:render]
      render result[:render], status: result[:status]
    else
      redirect_to @ministry
    end
  end

  def destroy
    @ministry.destroy
    redirect_to ministries_url
  end

  protected
  def find_ministry
    @ministry = Ministry.find(params[:id])
  end

end
