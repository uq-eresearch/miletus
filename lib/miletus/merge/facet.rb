module Miletus::Merge

  class Facet < ActiveRecord::Base

    self.table_name = 'merge_facets'

    attr_accessible :key, :metadata
    belongs_to :concept, :touch => true

    after_save :reindex_concept

    def reindex_concept
      concept.update_indexed_attributes_from_facet_rifcs
    end

    def to_rif
      begin
        doc = Nokogiri::XML(metadata)
        doc.root.nil? ? nil : doc.root.to_s
      rescue
        nil
      end
    end

  end

end