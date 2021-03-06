require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::AdminUsersController do
  it_behaves_like "an admin page"

  render_views

  before(:each) do
    @user = AdminUser.find_by_email!('admin@example.com')
    sign_in @user
  end

  describe "GET new" do
    before(:each) do
      get :new
    end

    it { should respond_with(:success) }
  end

end