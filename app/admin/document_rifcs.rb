require 'miletus'

ActiveAdmin.register Miletus::Harvest::Document::RIFCS,
  :as => "Direct RIF-CS Documents" do

  menu :parent => 'Documents'

  scope :unmanaged

  index do
    selectable_column
    column :url
    column :etag
    column :last_modified
    column :document_file_size
    column :created_at
    column :updated_at
    default_actions
  end

  form do |f|
    f.inputs "RIF-CS Document" do
      f.input :url
    end
    f.actions
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
