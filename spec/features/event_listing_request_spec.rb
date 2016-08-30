require 'rails_helper'

describe "the event listing page" do
  it "listing should show blank Location if no location_id exists" do
    event = create(:event, :location_id => nil, :title => 'mytitle')
    create(:event_session, event: event, starts_at: 1.day.from_now, ends_at: 2.days.from_now)

    visit events_path
    expect(page).to have_content('Upcoming events')
  end

  it "listing should show formatted dates" do
    next_year = Time.now.year + 1
    event = create(:event,
                   location_id: nil,
                   title: 'mytitle2',
                   time_zone: 'Pacific Time (US & Canada)')
    event.event_sessions.first.update_attributes(
      starts_at: Time.utc(next_year, 01, 31, 11, 20),
      ends_at: Time.utc(next_year, 01, 31, 11, 55)
    )

    event.save!
    event.reload

    visit events_path
    expect(page).to have_content("January 31, #{next_year}")
  end

  context 'as a non-logged in user', js: true do
    before do
      @user = create(:user)
    end

    it "listing should redirect to event detail page when non-logged in user volunteers" do
      event = create(:event, time_zone: 'Pacific Time (US & Canada)')
      event.event_sessions.first.update_attributes(
        starts_at: 365.days.from_now,
        ends_at: 366.days.from_now
      )
      event.save!

      visit events_path

      expect(page).to have_link("Attend as a student")
      expect(page).to have_link('Volunteer')
      click_link "Attend as a student"

      sign_in_with_modal(@user)

      expect(page.find('div.header-container > h1')).to have_content("#{event.title}")
      expect(current_path).to eq(event_path(event))
    end
  end

  context 'as a logged in user' do
    before(:each) do
      @user = create(:user)
      sign_in_as(@user)
    end

    context 'when organizing an event', js: true do
      before do
        visit events_path
        click_link "Organize Event"
      end

      it "can create a new course" do
        fill_in_good_event_details
        
        fill_in "event_target_audience", :with => "women"
        fill_in "event_details", :with => "This is a note in the detail text box\n With a new line!<script>alert('hi')</script> and a (missing) javascript injection, as well as an unclosed <h1> tag"
        check("coc")
        click_button submit_for_approval_button

        expect(page).to have_content good_event_title
        expect(page).to have_content("My Amazing Session")
        expect(page).to have_content("This event currently has no location!")
        #note the closed <h1> and missing script tags
        expect(page.body).to include("This is a note in the detail text box\n<br> With a new line!alert('hi') and a (missing) javascript injection, as well as an unclosed </p><h1> tag</h1>")
        expect(page).to have_css '.details br'
        expect(page).not_to have_css '.details script'
        expect(page).to have_content("1/12/2055")
        expect(page).to have_css(".details p", text: 'With a new line!')
        expect(page).to have_content("This is a Ruby on Rails event. The focus will be on developing functional web apps and programming in Ruby.")

        visit events_path

        expect(page).to have_content good_event_title
        expect(page).to have_content("Organizer Console")
      end

      it "can create a non-teaching event" do
        fill_in "Title", with: "Volunteer Work Day"
        fill_in "event_target_audience", :with => "women"
        choose "Just Volunteers"

        within ".event-sessions" do
          fill_in "Session Name", with: 'Do Awesome Stuff'
          fill_in_event_time
          uncheck "Required for Students?"
        end

        select "(GMT-09:00) Alaska", from: 'event_time_zone'
        fill_in "event_details", :with => "This is a note in the detail text box\n With a new line!<script>alert('hi')</script> and a (missing) javascript injection, as well as an unclosed <h1> tag"
        check("coc")
        click_button submit_for_approval_button

        expect(page).to have_content("Volunteer Work Day")
        expect(page).to have_content("Do Awesome Stuff")
        expect(page).to have_content("Organizer Console")

        expect(Event.last.course).to be_nil
        expect(Event.last.allow_student_rsvp).to be false
      end

      it "should display frontend content for frontend events" do
        visit events_path
        click_link "Organize Event"

        fill_in "Title", with: "March Event"
        fill_in "event_target_audience", :with => "women"
        select "Front End", :from => "event_course_id"
        fill_in "Student RSVP limit", with: 100

        within ".event-sessions" do
          fill_in "Session Name", with: good_event_session_name
          fill_in_event_time
        end

        select "(GMT-09:00) Alaska", from: 'event_time_zone'
        fill_in "event_details", :with => "This is a note in the detail text box\n With a new line!<script>alert('hi')</script> and a (missing) javascript injection, as well as an unclosed <h1> tag"
        check("coc")
        click_button submit_for_approval_button

        expect(page).to have_content("This is a Front End workshop. The focus will be on")
      end
    end

    context 'given an event' do
      before(:each) do
        @event = create(:event)
        @session1 = @event.event_sessions.first
        @session1.update_attributes!(name: 'Installfest', starts_at: 10.days.from_now, ends_at: 11.days.from_now)
        @session2 = create(:event_session, event: @event, name: 'Curriculum', starts_at: 12.days.from_now, ends_at: 13.days.from_now)
        @event.reload
      end

      context 'when volunteering' do
        before do
          visit events_path
          click_link("Volunteer")
          fill_in "rsvp_subject_experience", :with => "I am cool and I use a Mac (but those two things are not related)"
        end

        it "allows registration as a teacher" do
          expect(page).to have_content("almost signed up")
          fill_in "rsvp_teaching_experience", :with => "I have taught all kinds of things."
          check 'Teaching'
          choose('rsvp_class_level_0')

          expect(page.first("input[name='rsvp[event_session_ids][]'][type='checkbox'][value='#{@session1.id}']")).to be_checked
          expect(page.first("input[name='rsvp[event_session_ids][]'][type='checkbox'][value='#{@session2.id}']")).to be_checked

          uncheck "Curriculum"

          click_button "Submit"
          expect(page).to have_content("Thanks for signing up")

          rsvp = Rsvp.last
          expect(rsvp).to be_teaching
          expect(rsvp).not_to be_taing
          expect(rsvp.user_id).to eq(@user.id)
          expect(rsvp.event_id).to eq(@event.id)

          expect(rsvp.rsvp_sessions.length).to eq(1)
          expect(rsvp.rsvp_sessions.first.event_session).to eq(@session1)
        end

        it "allows registration without course level for non-teaching roles" do
          fill_in "rsvp_teaching_experience", :with => "I have taught all kinds of things."

          click_button "Submit"
          expect(page).to have_content("Thanks for signing up")

          rsvp = Rsvp.last
          expect(rsvp).not_to be_teaching
          expect(rsvp).not_to be_taing
          expect(rsvp.user_id).to eq(@user.id)
          expect(rsvp.event_id).to eq(@event.id)
        end
      end

      it "allows a student to register for an event" do
        visit events_path
        click_link("Attend as a student")
        expect(page).to have_content("almost signed up")

        choose "Windows 8"
        fill_in "rsvp_job_details", :with => "I am an underwater basket weaver."
        choose "rsvp_class_level_1"

        click_button "Submit"
        expect(page).to have_content("signed up")

        rsvp = Rsvp.last
        expect(rsvp.user_id).to eq(@user.id)
        expect(rsvp.event_id).to eq(@event.id)
        expect(rsvp.operating_system).to eq(OperatingSystem::WINDOWS_8)

        expect(rsvp.rsvp_sessions.length).to eq(2)
      end

      context 'given a volunteered user' do
        before(:each) do
          @rsvp = create(:teacher_rsvp, event: @event, user: @user)
          visit events_path
        end

        it "allows user to cancel their event RSVP" do
          click_link('Cancel RSVP')
          expect(Rsvp.find_by_id(@rsvp.id)).to be_nil
        end

        it "allows user to edit volunteer responsibilities" do
          click_link("Edit RSVP")
          uncheck 'Teaching'
          check 'TAing'

          uncheck "Installfest"
          check "Curriculum"

          click_button 'Submit'

          @rsvp.reload
          expect(@rsvp).to be_taing
          expect(@rsvp).not_to be_teaching

          expect(@rsvp.rsvp_sessions.length).to eq(1)
          expect(@rsvp.rsvp_sessions.first.event_session).to eq(@session2)
        end
      end
    end
  end
end
