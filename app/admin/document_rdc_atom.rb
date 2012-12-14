require 'miletus'

ActiveAdmin.register Miletus::Harvest::Document::RDCAtom,
  :as => "Direct RDC Atom Documents" do

  menu :parent => 'Documents'

  scope :unmanaged, :default => true
  scope :all

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
    f.inputs "RDC Atom Document" do
      f.input :url
    end
    f.actions
  end

  batch_action :fetch do |selection|
    Miletus::Harvest::Document::RDCAtom.find(selection).each do |doc|
      doc.delay.fetch
    end
    flash[:notice] = \
      "Scheduled fetch for selected documents."
    redirect_to :action => :index
  end

end
