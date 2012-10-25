require 'miletus'

ActiveAdmin.register Miletus::Harvest::Document::RIFCS,
  :as => "Direct RIF-CS Documents" do

  form do |f|
    f.inputs "RIF-CS Document" do
      f.input :url
    end
    f.buttons
  end

  batch_action :fetch do |selection|
    Miletus::Harvest::Document::RIFCS.find(selection).each do |doc|
      doc.delay.fetch
    end
    flash[:notice] = \
      "Scheduled fetch for selected documents."
    redirect_to :action => :index
  end

end
