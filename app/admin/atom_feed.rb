require 'miletus'

ActiveAdmin.register Miletus::Harvest::Atom::Feed,
  :as => "Atom Feed" do

  index do
    selectable_column
    column :url
    column :updated_at
    default_actions
  end

end
