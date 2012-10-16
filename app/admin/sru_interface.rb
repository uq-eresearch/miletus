require 'miletus'

ActiveAdmin.register Miletus::Harvest::SRU::Interface,
  :as => "SRU Lookup Interface" do

  index do
    selectable_column
    column :endpoint
    column :schema
    column :exclude_xpaths do |interface|
      unless interface.exclude_xpaths.nil?
        simple_format interface.exclude_xpaths.join("\n")
      end
    end
    default_actions
  end

  filter :endpoint

  form do |f|
    f.inputs "SRU Lookup Interface Details" do
      f.input :endpoint
      f.input :schema
      f.input :exclude_xpaths
    end
    f.buttons
  end

end
