require 'rails_helper'

feature "Accepting friendship" do

  background do
    @user = create(:user)
    @user2 = create(:user)
    log_in(@user)
  end

  scenario "makes both friendships accepted", :js => true do
    visit profiles_path(@user2)
    click_link "Add Friend"

    log_out(@user)
    log_in(@user2)

    visit friendships_path
    click_link "Edit"
    click_button "Accept friendship"
    expect(page).to have_content("Active")

    log_out(@user2)
    log_in(@user)
    
    visit friendships_path
    expect(page).to have_content("Active")
  end

end
