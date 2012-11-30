require 'miletus'

ActiveAdmin.register Miletus::Harvest::Atom::Feed,
  :as => "Atom Feed" do

  menu :parent => 'Harvest'

  sidebar "Maintenance" do
    para do
      button_to "Harvest", :action => :harvest, :method => :post
    end
  end

  collection_action :harvest, :method => :post do
    Miletus::Harvest::Atom.jobs.each do |job|
      job.delay.perform
    end
    flash[:notice] = "Scheduled harvest for all feeds."
    redirect_to :action => :index
  end

  index do
    selectable_column
    column :url
    column :updated_at
    default_actions
  end

end
