module Miletus::Merge

  class Concept < ActiveRecord::Base

    self.table_name = 'merge_concepts'

    has_many :facets, :dependent => :destroy, :order => 'updated_at DESC'
    has_many :indexed_attributes,
      :dependent => :destroy, :order => [:key, :value]

    def to_rif
      input_docs = facets.map {|f| f.to_rif}.reject {|xml| xml.nil?}\
        .map {|xml| RifCsDoc.new(xml)}
      return nil if input_docs.empty?
      rifcs_doc = input_docs.first.clone
      rifcs_doc.merge_rifcs_identifiers(input_docs).to_s
    end

    class RifCsDoc
      include Miletus::NamespaceHelper

      def initialize(xml)
        @doc = Nokogiri::XML(xml)
      end

      def identifiers
        @doc.xpath("//rif:identifier", ns_decl)
      end

      def merge_rifcs_identifiers(input_docs)
        # Get all identifier elements, unique in content
        identifiers = deduplicate_by_content(input_docs.map {|d| d.identifiers})
        types = %w{collection party activity service}
        pattern = types.map { |e| "//rif:#{e}"}.join(' | ')
        base = @doc.at_xpath(pattern, ns_decl)
        base.xpath("//rif:identifier", ns_decl).remove
        base.children.first.before(
          Nokogiri::XML::NodeSet.new(@doc, identifiers))
        base.xpath("//rif:identifier", ns_decl).each do |n|
          n.namespace = base.namespace
        end
        self
      end

      def to_s
        @doc.to_s
      end

      private

      def deduplicate_by_content(nodesets)
        nodesets.map {|n| n.to_ary}.reduce(:|).uniq {|e| e.content.strip }
      end

    end



  end

end