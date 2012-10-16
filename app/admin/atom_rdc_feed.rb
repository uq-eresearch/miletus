require 'miletus'

ActiveAdmin.register Miletus::Harvest::Atom::RDC::Feed,
  :as => "Atom RDC Feed" do

  index do
    selectable_column
    column :url
    default_actions
  end

end
