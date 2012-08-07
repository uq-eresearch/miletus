module Miletus::Merge

  class Facet < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'merge_facets'

    attr_accessible :key, :metadata
    belongs_to :concept, :touch => true

    after_save :reindex_concept

    def reindex_concept
      concept.update_indexed_attributes_from_facet_rifcs
    end

    def to_rif
      doc = Nokogiri::XML(metadata)
      ns_by_prefix('rif').schema.valid?(doc) ? doc.root.to_s : nil
    end

  end

end