require 'miletus'

ActiveAdmin.register Miletus::Harvest::SRU::Interface,
  :as => "SRU Lookup Interface" do

  menu :parent => 'Harvest'

  index do
    selectable_column
    column :endpoint
    column :schema
    column "XPaths to Exclude from Response" do |interface|
      interface.exclude_xpaths_string
    end
    default_actions
  end

  filter :endpoint

  form do |f|
    f.inputs "SRU Lookup Interface Details" do
      f.input :endpoint
      f.input :schema
      f.input :exclude_xpaths_string, :as => :text,
        :label => "XPaths to Exclude from Response"
    end
    f.buttons
  end

end
