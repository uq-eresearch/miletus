require 'miletus'

require File.join(File.dirname(__FILE__), 'shared')

ActiveAdmin.register Miletus::Merge::Facet,
  :as => "Facet" do
  menu false

  index do
    selectable_column
    column :concept
    column :key
    column :updated_at
    column '' do |resource|
      view_delete_buttons(resource_path(resource))
    end
  end

  show do
    attributes_table do
      row :id
      row :concept
      row :key
      row "Raw Metadata" do |facet|
        pre facet.metadata, :class => 'prettyprint'
      end
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end



end
