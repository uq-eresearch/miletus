require 'spec_helper'

shared_context "logged in as admin" do

  before(:each) do
    @user = AdminUser.find_by_email!('admin@example.com')
    sign_in @user
  end

end

shared_examples "an admin page" do
  include_context "logged in as admin"
  render_views

  describe "GET index" do
    before(:each) { get :index }

    it "is successful" do
      response.should be_success
    end
  end

  describe "GET new" do
    before(:each) do
      get :new
    end

    it "is successful" do
      response.should be_success
    end
  end
end