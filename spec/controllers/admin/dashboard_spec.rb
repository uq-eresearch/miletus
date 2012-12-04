require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::DashboardController do
  include_context "logged in as admin"
  render_views

  describe "GET index" do
    before(:each) { get :index }

    it "is successful" do
      response.should be_success
    end
  end
end