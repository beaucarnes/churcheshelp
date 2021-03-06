def sign_in_as(user, options={})
  if options[:slowly]
    visit new_user_session_path
    within("#sign-in-page") do
      fill_in "Email", :with => user.email
      fill_in "Password", :with => user.password
      click_button "Sign in"
    end
    expect(page).to have_content("Signed in successfully")
  else
    login_as user, scope: :user
  end
end

def sign_in_with_modal(user)
  expect(page).to have_selector('#sign_in_dialog', visible: true)
  within "#sign_in_dialog" do
    fill_in "Email", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end
end

def sign_in_stub(fake_user)
  if fake_user.nil?
    allow(request.env['warden']).to receive(:authenticate!).
      and_throw(:warden, {:scope => :user})
    allow(controller).to receive_messages :current_user => nil
  else
    allow(request.env['warden']).to receive_messages :authenticate! => fake_user
    allow(controller).to receive_messages :current_user => fake_user
  end
end