module Miletus::Merge

  class Facet < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'merge_facets'

    attr_accessible :metadata
    belongs_to :concept, :touch => true

    before_validation :update_key
    after_save :reindex_concept

    def self.find_existing(xml)
      find_by_key(global_key(xml))
    end

    def reindex_concept
      concept.update_indexed_attributes_from_facet_rifcs
    end

    def to_rif
      doc = Nokogiri::XML(metadata)
      ns_by_prefix('rif').schema.valid?(doc) ? doc.root.to_s : nil
    end

    private

    def update_key
      write_attribute(:key, self.class.global_key(metadata))
    end

    def self.global_key(xml)
      return nil if xml.nil?
      doc = Nokogiri::XML(xml)
      key_e = doc.at_xpath('//rif:registryObject/rif:key',
        Miletus::NamespaceHelper.ns_decl)
      begin
        key_e.content.strip
      rescue NoMethodError
        nil
      end
    end


  end

end