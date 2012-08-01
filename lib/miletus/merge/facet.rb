module Miletus::Merge

  class Facet < ActiveRecord::Base

    self.table_name = 'merge_facets'

    attr_accessible :key, :metadata
    belongs_to :concept, :touch => true

    def to_rif
      begin
        doc = Nokogiri::XML(metadata)
        doc.root.nil? ? nil : doc.to_s
      rescue
        nil
      end
    end

  end

end