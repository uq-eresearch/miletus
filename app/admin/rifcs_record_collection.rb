require 'miletus'

ActiveAdmin.register Miletus::Harvest::OAIPMH::RIFCS::RecordCollection,
  :as => "RIFCS-over-OAIPMH Record Collection" do

  menu :parent => 'Harvest'

  sidebar "Maintenance" do
    para do
      button_to "Harvest", :action => :harvest, :method => :post
    end
  end

  collection_action :harvest, :method => :post do
    Miletus::Harvest::OAIPMH::RIFCS.jobs.each do |job|
      job.delay.perform
    end
    flash[:notice] = "Scheduled harvest for all OAI-PMH endpoints."
    redirect_to :action => :index
  end

  index do
    selectable_column
    column :endpoint
    default_actions
  end

end
