require 'miletus'

ActiveAdmin.register Miletus::Merge::Concept,
  :as => "Concept" do

  sidebar :recheck_sru do
    button_to "Recheck SRU", :action => :recheck_sru, :method => :post
  end

  batch_action :recheck_sru do |selection|
    Miletus::Merge::Concept.find(selection).each do |concept|
      SruRifcsLookupObserver.instance.find_sru_records(concept)
    end
    flash[:notice] = \
      "Scheduled recheck for selected concepts from SRU interfaces."
    redirect_to :action => :index
  end

  collection_action :recheck_sru, :method => :post do
    Miletus::Merge::Concept.all.each do |concept|
      SruRifcsLookupObserver.instance.find_sru_records(concept)
    end
    flash[:notice] = "Scheduled recheck for all concepts from SRU interfaces."
    redirect_to :action => :index
  end

  index do
    selectable_column
    column :type
    column :subtype
    column :title do |concept|
      link_to concept.title, concept_path(concept.id)
    end
    column :facets_count
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
      row :type
      row :subtype
      row :titles do |concept|
        concept.titles.each do |title|
          div title
        end
      end
      row :facets_count
      row 'Indexed Attributes' do |concept|
        concept.indexed_attributes.order('key, value').each do |i|
          dl do
            dt i.key
            dd i.value
          end
        end
      end
    end
    active_admin_comments
  end

end
