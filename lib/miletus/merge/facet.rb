module Miletus::Merge

  class Facet < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'merge_facets'

    attr_accessible :metadata

    belongs_to :concept,
      :counter_cache => :facets_count,
      :touch => true

    before_validation :update_key
    after_save :reindex_concept
    after_destroy :destroy_empty_concept

    def self.find_existing(xml)
      find_by_key(global_key(xml))
    end

    def reindex_concept
      concept.reindex unless concept.nil?
    end

    def to_rif
      doc = clean_rifcs_doc(Nokogiri::XML(metadata))
      ns_by_prefix('rif').schema.valid?(doc) ? doc.root.to_s : nil
    end

    private

    def destroy_empty_concept
      return if self.concept.nil?
      self.concept.reload
      concept.destroy if self.concept.facets.count == 0
    end

    def update_key
      k = self.class.global_key(metadata)
      write_attribute(:key, k) unless k.nil?
    end

    def self.global_key(xml)
      return nil if xml.nil?
      doc = Nokogiri::XML(xml)
      key_e = doc.at_xpath('//rif:registryObject/rif:key',
        Miletus::NamespaceHelper.ns_decl)
      return nil if key_e.nil?
      key_e.content.strip
    end

    def clean_rifcs_doc(doc)
      translate_old_elements(doc)
      update_datetime(doc)
      strip_schema_location(doc)
      doc
    end

    def update_datetime(rifcs_doc)
      types = %w{collection party activity service}
      pattern = types.map { |e| "//rif:#{e}"}.join(' | ')
      rifcs_doc.xpath(pattern, ns_decl).each do |e|
        e['dateModified'] = (updated_at or Time.now).utc.iso8601
      end
    end

    def translate_old_elements(rifcs_doc)
      types = {'rights' => 'rightsStatement', 'accessRights' => 'accessRights'}
      # For those description elements we can translate...
      find_description_elements_with_types(rifcs_doc, types.keys).each do |e|
        # Get the rights element or create it if necessary
        rights = find_or_create_rifcs_rights_element(e.parent)
        # Create new element based on attribute name and insert it
        node = Nokogiri::XML::Node.new(types[e['type'].to_s], rifcs_doc)
        node.content = e.content
        rights << node
        e.remove
      end
    end

    def strip_schema_location(rifcs_doc)
      n = rifcs_doc.root
      n.remove_attribute('schemaLocation') unless n.nil?
    end

    def find_description_elements_with_types(rifcs_doc, types)
      pattern = types.map do |t|
        "//rif:description[@type=\"%s\"]" % t
      end.join("|")
      rifcs_doc.xpath(pattern, ns_decl)
    end

    def find_or_create_rifcs_rights_element(node)
      rights = node.at_xpath("rif:rights", ns_decl)
      rights ||= Nokogiri::XML::Node.new('rights', node.document)
      node << rights
      rights
    end

  end

end