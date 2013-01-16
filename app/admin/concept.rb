require 'miletus'

require File.join(File.dirname(__FILE__), 'shared')

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

  {
    :reindex => 'Selected concepts have been reindexed.',
    :split => 'Selected concepts have been split.'
  }.each do |method_sym, message|
    batch_action method_sym do |selection|
      Miletus::Merge::Concept.find(selection).each(&method_sym)
      flash[:notice] = message
      redirect_after_action(selection)
    end
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
      view_delete_buttons(resource_path(resource))
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
        # Facets merge in reverse order by size, so display in same order
        concept.facets.sort_by do |facet|
          # Sort by size
          facet.metadata ? facet.metadata.length : 0
        end.reverse.each do |facet|
          facet_link = link_to(facet.key, admin_facet_path(facet))
          if facet.metadata
            # Show link and file size
            links << div(
              "#{facet_link} (#{facet.metadata.length} bytes)".html_safe)
          else
            links << div(facet_link)
          end
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
      row "Merged RIF-CS Metadata" do |facet|
        pre concept.to_rif, :class => 'prettyprint'
      end
    end
    active_admin_comments
  end

end
