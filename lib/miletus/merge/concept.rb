module Miletus::Merge

  class Concept < ActiveRecord::Base
    include Miletus::NamespaceHelper

    self.table_name = 'merge_concepts'

    has_many :facets, :dependent => :destroy, :order => 'updated_at DESC'
    has_many :indexed_attributes,
      :dependent => :destroy, :order => [:key, :value]

    def to_rif
      input_docs = facets.map {|f| f.to_rif}.reject do |xml|
        xml.nil? or Nokogiri::XML(xml).root.nil?
      end
      return nil if input_docs.empty?
      output_doc = input_docs.first.clone
      output_doc = merge_rifcs_identifiers(input_docs, output_doc)
    end

    def merge_rifcs_identifiers(input_docs, output_doc)
      # Get all identifier elements, unique in content
      identifiers = input_docs.map do |xml|
        Nokogiri::XML(xml).xpath("//rif:identifier", ns_decl).map {|n| n.dup}
      end.reduce(:|).uniq {|e| e.content.strip}
      # Remove identifiers from output and substitute merged set
      output_doc = Nokogiri::XML(output_doc)
      types = %w{collection party activity service}
      pattern = types.map { |e| "//rif:#{e}"}.join(' | ')
      base = output_doc.at_xpath(pattern, ns_decl)
      base.xpath("//rif:identifier", ns_decl).remove
      base.children.first.before(
        Nokogiri::XML::NodeSet.new(output_doc, identifiers))
      base.xpath("//rif:identifier", ns_decl).each do |n|
        n.namespace = base.namespace
      end
      output_doc.to_s
    end


  end

end