require 'miletus'

ActiveAdmin.register Miletus::Merge::Concept,
  :as => "Concept" do

  controller do
    module LinkToBatchHelper
      def link_to_batch(action, title = nil)
        link_to(title || action.to_s.titleize, {
            :action => :batch_action,
            :batch_action => action,
            :collection_selection => [params[:id]]
          }, :method => :post)
      end
    end

    def redirect_after_action(selection = [])
      if selection.count == 1
        redirect_to :action => :show, :id => selection.first
      else
        redirect_to :action => :index
      end
    end
  end

  sidebar "Maintenance", :only => :index do
    para do
      button_to "Recheck SRU", :action => :recheck_sru, :method => :post
    end
    para do
      button_to "Reindex", :action => :reindex, :method => :post
    end
    para do
      button_to "Deduplicate", :action => :deduplicate, :method => :post
    end
  end

  batch_action :merge,
    :confirm => "Are you sure you want to merge these concepts?" do |selection|
    concepts = Miletus::Merge::Concept
    merged_concept = concepts.merge(concepts.find(selection))
    flash[:notice] = \
      "Merged selected concepts."
    redirect_to :action => :show, :id => merged_concept.id
  end

  action_item do
    extend controller.class.const_get('LinkToBatchHelper')
    link_to_batch :recheck_sru, "Recheck SRU" if params[:id]
  end

  action_item do
    extend controller.class.const_get('LinkToBatchHelper')
    link_to_batch :reindex if params[:id]
  end

  action_item do
    extend controller.class.const_get('LinkToBatchHelper')
    link_to_batch :split if params[:id]
  end

  batch_action :recheck_sru do |selection|
    Miletus::Merge::Concept.find(selection).each do |concept|
      SruRifcsLookupObserver.instance.find_sru_records_for_concept(concept)
    end
    flash[:notice] = \
      "Scheduled recheck for selected concepts from SRU interfaces."
    redirect_after_action(selection)
  end

  batch_action :reindex do |selection|
    Miletus::Merge::Concept.find(selection).each(&:reindex)
    flash[:notice] = "Selected concepts have been reindexed."
    redirect_after_action(selection)
  end

  batch_action :split do |selection|
    Miletus::Merge::Concept.find(selection).each(&:split)
    flash[:notice] = "Selected concepts have been split up."
    redirect_after_action(selection)
  end

  collection_action :recheck_sru, :method => :post do
    Miletus::Merge::Concept.all.each do |concept|
      SruRifcsLookupObserver.instance.find_sru_records_for_concept(concept)
    end
    flash[:notice] = "Scheduled recheck for all concepts from SRU interfaces."
    redirect_after_action
  end

  collection_action :reindex, :method => :post do
    Miletus::Merge::Concept.all.each(&:reindex)
    flash[:notice] = "All concepts have been reindexed."
    redirect_after_action
  end

  collection_action :deduplicate, :method => :post do
    Miletus::Merge::Concept.deduplicate
    flash[:notice] = "Finished merging duplicate concepts."
    redirect_after_action
  end

  index do
    selectable_column
    column :type
    column :subtype
    column :title do |concept|
      link_to concept.title, concept_id_path(concept.id)
    end
    column "No. of Facets" do |concept|
      link_to(concept.facets.count, resource_path(concept))
    end
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
        (concept.titles || []).each do |title|
          div title
        end
      end
      row :facets do |concept|
        links = ''.html_safe
        concept.facets.each do |facet|
          links << div(link_to(facet.key, admin_facet_path(facet)))
        end
        links
      end
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
