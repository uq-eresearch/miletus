require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::DelayedJobsController do
  it_behaves_like "an admin page"

  render_views

  before(:each) do
    @user = AdminUser.find_by_email!('admin@example.com')
    sign_in @user
  end

  describe "GET :index" do
    context "when a job exists" do
      before(:each) do
        1.delay.succ # Add a new job to the queue
        puts Delayed::Job.methods.inspect
        Delayed::Job.count.should be == 1
        get :index
      end

      it { should respond_with(:success) }
    end
  end

  describe "POST :clear" do
    before(:each) do
      1.delay.succ # Add a new job to the queue
      Delayed::Job.count.should be == 1
      post :clear
    end

    it { should respond_with(:redirect) }

    it "should clear all existing jobs" do
      Delayed::Job.count.should be == 0
    end
  end

end