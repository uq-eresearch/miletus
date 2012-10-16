require 'miletus'

ActiveAdmin.register Miletus::Harvest::OAIPMH::RIFCS::RecordCollection,
  :as => "RIFCS-over-OAIPMH Record Collection" do

  index do
    selectable_column
    column :endpoint
    default_actions
  end

end
