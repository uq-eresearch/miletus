require 'miletus'

ActiveAdmin.register Miletus::Merge::Facet,
  :as => "Facet" do
  menu false

  index do
    selectable_column
    column :concept
    column :key
    column :updated_at
    column '' do |resource|
      links = ''.html_safe
      links << link_to(I18n.t('active_admin.view'), resource_path(resource),
        :class => "member_link view_link")
      links << link_to(I18n.t('active_admin.delete'), resource_path(resource),
        :method => :delete,
        :data => {:confirm => I18n.t('active_admin.delete_confirmation')},
        :class => "member_link delete_link")
      links
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
