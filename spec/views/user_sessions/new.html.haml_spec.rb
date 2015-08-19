require 'spec_helper'

describe "user_sessions/new.html.haml" do
  before do
    activate_authlogic
    assign(:user_session, UserSession.new)
    assign(:user, User.new)
  end

  context "when the flash has verifying user email info in it" do
    before { flash[:email_to_verify] = email }
    let(:email) { 'some_email' }

    it "should populate the email field with the verifying user email" do
      render
      rendered.should have_selector("input[id=user_session_email][value=#{email}]")
    end
  end

  context "when the flash has no verifying user email info in it" do
    it "should use an empty email field" do
      render
      rendered.should_not have_selector("input[id=user_session_email][value]")
    end
  end
end
