# Un-ruby pattern required by lib-xml `find` calls:
# http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000475
#
# Please don't refactor it away unless you like segfaults!
require 'nokogiri'

module Miletus::Output::OAIPMH

  class Record < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'output_oaipmh_records'

    attr_accessible :metadata
    belongs_to :underlying_concept,
      :class_name => 'Miletus::Merge::Concept'
    has_and_belongs_to_many :sets,
      :class_name => 'Set',
      :join_table => 'output_oaipmh_record_set_memberships',
      :uniq => true

    validate :valid_rifcs?
    after_validation :clean_metadata
    after_save :update_set_memberships

    @@schemas = {}

    def to_oai_dc
      return nil unless valid_rifcs?
      wrapper = RifCSToOaiDcWrapper.new(to_rif)
      OAI::Provider::Metadata::DublinCore.instance.encode(wrapper, wrapper)
    end

    def deleted?
      underlying_concept.nil? ? false : underlying_concept.facets.empty?
    end

    def metadata=(xml)
      if xml.nil? or xml == ''
        write_attribute(:metadata, '')
      else
        xml = Nokogiri::XML(xml).root.to_s
        write_attribute(:metadata, xml == "<xml/>" ? nil : xml)
      end
    end

    def self.sets
      Miletus::Output::OAIPMH::Set.scoped
    end

    def to_rif
      metadata
    end

    protected

    def record_type
      Nokogiri::XML(to_rif).at_xpath(
        "//rif:registryObject/*[last()]", ns_decl).name
    end

    def update_set_memberships
      type_attrs = Nokogiri::XML(to_rif).xpath(
        "//rif:identifier/@type", ns_decl)
      type_attrs.map{|a| a.value}.each do |type|
        spec = "#{record_type}:identifier:#{type}"
        set = Miletus::Output::OAIPMH::Set.find_or_create_by_spec(
          :spec => spec,
          :name => "#{type} identifier #{record_type}")
        set.records << self
      end
    end

    def clean_metadata
      return if read_attribute(:metadata).nil?
      xml = Nokogiri::XML(read_attribute(:metadata)).tap do |xml|
          update_datetime(xml)
        end.root.to_s
      write_attribute(:metadata, xml)
    end

    def update_datetime(rifcs_doc)
      types = %w{collection party activity service}
      pattern = types.map { |e| "//rif:#{e}"}.join(' | ')
      rifcs_doc.xpath(pattern, ns_decl).each do |e|
        e['dateModified'] = Time.now.utc.iso8601
      end
    end

    def valid_rifcs?
      ns_by_prefix('rif').schema.valid?(Nokogiri::XML(metadata))
    end

    class RifCSToOaiDcWrapper
      include Miletus::NamespaceHelper

      def initialize(rifcs)
        @doc = Nokogiri::XML(rifcs)
      end

      def identifier
        nodes = @doc.xpath('//rif:identifier', ns_decl)
        nodes.map { |identifier| identifier.content.strip }
      end

      def title
        get_name_parts.map do |parts|
          cond_tmpl(parts, [nil], "%s") or
            cond_tmpl(parts, %w{family given}, "%s, %s")
        end
      end

      def date
        @doc.xpath('//@dateModified', ns_decl).map {|d| d.value }
      end

      def description
        types = %w{collection party activity service}
        pattern = types.map { |e| "//rif:#{e}/rif:description"}.join(' | ')
        @doc.xpath(pattern, ns_decl).map {|d| d.content }
      end

      def rights
        @doc.xpath("//rif:rights/*", ns_decl).map {|d| d.content }
      end

      private

      def cond_tmpl(h, keys, tmpl)
        return nil unless keys.all? {|k| h.has_key?(k) }
        tmpl % h.values_at(*keys).map {|values| values.join(" ") }
      end

      def get_name_parts
        @doc.xpath("//rif:name", ns_decl).map do |e|
          e.xpath("rif:namePart", ns_decl).each_with_object({}) do |part, h|
            k = part.key?('type') ? part['type'].to_s : nil
            (h[k] ||= []) << part.content.strip
          end
        end
      end

    end

  end

end
