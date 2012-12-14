require 'miletus'
require 'delayed_job_active_record'

ActiveAdmin.register Delayed::Backend::ActiveRecord::Job,
  :as => "Delayed Job" do

  scope :all, :default => true
  scope :with_errors do |jobs|
    jobs.where('last_error IS NOT NULL')
  end

  sidebar "Maintenance" do
    para do
      button_to "Clear All", :action => :clear, :method => :post
    end
  end

  collection_action :clear, :method => :post do
    Delayed::Job.delete_all
    flash[:notice] = "Cleared all pending jobs."
    redirect_to :action => :index
  end

  index do
    selectable_column
    column :priority
    column :attempts
    column :handler
    column :last_error
    column :queue
    column :updated_at
    default_actions
  end

end
