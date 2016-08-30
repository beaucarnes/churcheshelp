class MinistryEditor
  attr_reader :current_user, :params

  def initialize(user, params)
    @current_user = user
    @params = params
  end

  def create
    ministry = Ministry.new(ministry_params)
    result = {
      ministry: ministry
    }

    unless ministry.save!
      return result.merge(
        render: :new
      )
    end


    if ministry.draft?
      result.merge(
        notice: 'Draft saved. You can continue editing.',
        render: :edit
      )
    elsif ministry.published?
      result.merge(
        notice: 'Ministry was successfully created.'
      )
    else
      mark_for_approval(ministry)

      result.merge(
        notice: 'Your ministry is awaiting approval and will appear to other users once it has been reviewed by an admin.'
      )
    end
  end

  def update(ministry)
    was_draft = ministry.draft?

    unless ministry.update_attributes(ministry_params(ministry))
      return {
        render: :edit,
        status: :unprocessable_entity
      }
    end

    if ministry.draft?
      {
        notice: 'Draft updated. You can continue editing.',
        render: :edit
      }
    else
      mark_for_approval(ministry) if was_draft

      {
        notice: 'Ministry was successfully updated.'
      }
    end
  end

  private

  def ministry_params(ministry = nil)
    permitted = Ministry::PERMITTED_ATTRIBUTES.dup


    derived_params = {}
    derived_params[:current_state] = :pending_approval
    if params[:save_draft]
      derived_params[:current_state] = :draft
    elsif !ministry || ministry.draft?
      derived_params[:current_state] = :pending_approval
    end
    params.require(:ministry).permit(permitted).merge(derived_params)
  end

  def mark_for_approval(ministry)
    if current_user.spammer?
      ministry.update_attribute(:spam, true)
    else
    #  MinistryMailer.unpublished_ministry(ministry).deliver_now
    #  MinistryMailer.ministry_pending_approval(ministry).deliver_now
    end
  end
end