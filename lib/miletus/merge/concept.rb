require 'equivalent-xml'
require 'set'

module Miletus::Merge

  class Concept < ActiveRecord::Base
    extend Miletus::NamespaceHelper
    include Miletus::NamespaceHelper

    self.table_name = 'merge_concepts'

    store :cache, :accessors => [
      :titles, :type, :subtype, :outbound_related_concept_keys]

    has_many :facets,
      :dependent => :destroy,
      :order => 'updated_at DESC'
    has_many :indexed_attributes,
      :dependent => :destroy, :order => [:key, :value]

    def group
      if ENV.has_key? 'CONCEPT_GROUP'
        # Get env variable (substitution fixes a common Foreman bug)
        ENV['CONCEPT_GROUP'].gsub('\ ', ' ')
      else
        key_prefix
      end
    end

    def key
      "%s%d" % [key_prefix, id]
    end

    def title
      (self.titles || []).first
    end

    def self.find_by_key!(key)
      _, _, id = key.partition(key_prefix)
      raise ActiveRecord::RecordNotFound("Invalid prefix") unless id =~ /^\d+$/
      find_by_id!(id.to_i)
    end

    def self.find_existing(xml)
      id_nodes = Nokogiri::XML(xml).xpath(
        '//rif:identifier', ns_decl)
      existing = id_nodes.map do |e|
        joins(:indexed_attributes).where(
          IndexedAttribute.table_name.to_sym => {
            :key => 'identifier',
            :value => e.content.strip
          }
        ).pluck(:concept_id)
      end.flatten
      return nil if existing.empty?
      find_by_id(existing.first)
    end

    def to_rif
      input_docs = rifcs_facets
      return nil if input_docs.empty?
      rifcs_doc = input_docs.first.clone
      rifcs_doc.merge_rifcs_elements(input_docs)
      rifcs_doc.group = group
      rifcs_doc.key = key
      rifcs_doc.translate_keys(related_key_dictionary)
      rifcs_doc.root.to_xml(:indent => 2)
    end

    def reindex
      update_indexed_attributes_from_facet_rifcs
      recache_attributes
    end

    def related_concepts
      inbound_related_concepts.to_set | outbound_related_concepts.to_set
    end

    def to_s
      "%s incorporating %s" % [key, facets.pluck(:key).inspect]
    end

    def self.to_gexf
      GexfDoc.new(self.all).to_xml
    end

    def to_gexf
      GexfDoc.new([self] | outbound_related_concepts).to_xml
    end

    def inbound_related_concepts
      in_keys = facets.pluck(:key)
      return [] if in_keys.compact.empty?
      self.class.joins(:indexed_attributes).where(
          ["#{tn(:indexed_attributes)}.key = 'relatedKey'",
           "#{tn(:indexed_attributes)}.value IN (?)"].join(' AND '),
          in_keys
        )
    end

    def outbound_related_concepts
      out_keys = indexed_attributes.where(:key => 'relatedKey').pluck(:value)
      return [] if out_keys.compact.empty?
      self.class.joins(:facets).where(
          "#{tn(:facets)}.key in (?)", out_keys
        )
    end

    private

    def update_indexed_attributes_from_facet_rifcs
      input_docs = rifcs_facets
      update_indexed_attributes('identifier',
        content_from_nodes(input_docs,
          '//rif:registryObject/rif:*/rif:identifier'))
      update_indexed_attributes('relatedKey',
        content_from_nodes(input_docs, '//rif:relatedObject/rif:key'))
      update_indexed_attributes('email',
        content_from_nodes(input_docs,
          '//rif:registryObject/rif:party/rif:location/rif:address'+
          '/rif:electronic[@type="email"]/rif:value'))
    end

    def recache_attributes
      rifcs_doc = RifcsDoc.create(to_rif)
      self.titles = rifcs_doc.titles
      self.type, self.subtype = rifcs_doc.types
      # Key index for faster graph generation
      out_keys = indexed_attributes.where(:key => 'relatedKey').pluck(:value)
      self.outbound_related_concept_keys = self.class.joins(:facets).where(
          "#{tn(:facets)}.key in (?)", out_keys
        ).map {|c| c.key}
      save!
    end

    def related_key_dictionary
      Hash[*outbound_related_concepts.map do |c|
        c.facets.map {|f| [f.key, c.key] }
      end.flatten]
    end

    def key_prefix
      self.class.key_prefix
    end

    def self.key_prefix
      @@key_prefix ||= if ENV.has_key? 'CONCEPT_KEY_PREFIX'
        ENV['CONCEPT_KEY_PREFIX']
      else
        require 'socket'
        'urn:%s:' % Socket.gethostname
      end
    end

    def tn(relation)
      self.class.reflect_on_association(relation).klass.table_name
    end

    def content_from_nodes(docs, xpath)
      docs.map{|doc| doc.xpath(xpath, ns_decl) # Get nodesets matching pattern
        }.map{|n| n.to_ary.map {|e| e.content.strip} # Get content values
        }.reduce(:|) or [] # Join arrays together, and handle nil case
    end

    def rifcs_facets
      facets.order(:created_at).map {|f| f.to_rif}.reject {|xml| xml.nil?}\
        .map {|xml| RifcsDoc.create(xml)}
    end

    def update_indexed_attributes(key, new_values)
      self.transaction do
        current_values = indexed_attributes.where(:key => key).select(:value)
        (new_values - current_values).each do |v|
          indexed_attributes.find_or_create_by_key_and_value(key, v)
        end
        indexed_attributes.where(:id => current_values - new_values).delete_all
      end
    end
  end

end