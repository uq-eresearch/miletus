require 'equivalent-xml'
require 'set'

module Miletus::Merge

  # Represents a single concept which may have many facets of information.
  #
  # For example, a person would be a _concept_, with individual _facets_ coming
  # from collection metadata repositories, an institutional HR system and the
  # National Library of Australia.
  #
  # Facets are grouped together into concepts using their common identifiers.
  class Concept < ActiveRecord::Base
    extend Miletus::NamespaceHelper
    include Miletus::NamespaceHelper

    self.table_name = 'merge_concepts'

    store :cache, :accessors => [:titles, :type, :subtype]

    has_many :facets,
      :dependent => :destroy,
      :order => 'updated_at DESC'

    has_many :indexed_attributes,
      :dependent => :destroy, :order => [:key, :value] do

      def update(key, new_values)
        proxy_association.reflection.klass\
          .update_for_concept(proxy_association.owner, key, new_values)
      end

    end

    before_save :generate_uuid

    validates_uniqueness_of :uuid, :allow_nil => true

    def self.updated_at
      self.order(:updated_at).reverse_order.first.try(:updated_at)
    end

    def group
      if ENV.has_key? 'CONCEPT_GROUP'
        # Get env variable (substitution fixes a common Foreman bug)
        ENV['CONCEPT_GROUP'].gsub('\ ', ' ')
      else
        key_prefix
      end
    end

    def key
      uuid && [key_prefix, uuid].join
    end

    # The primary name this concept is known by. (eg. "Howard Walter Florey")
    def title
      title = (self.titles || []).first
      title.nil? || title == '' ? self.key : title
    end

    # Other titles associated with this concept. (eg. "Baron Florey")
    def alternate_titles
      self.titles[1..-1] || [] rescue []
    end

    def self.find_by_key!(key)
      _, _, uuid = key.partition(key_prefix)
      begin
        UUIDTools::UUID.parse(uuid)
      rescue ArgumentError
        raise ActiveRecord::RecordNotFound("Invalid prefix")
      end
      find_by_uuid!(uuid)
    end

    # Find an existing concept with a matching identifier, using the given
    # RIF-CS XML.
    def self.find_existing(xml)
      id_nodes = Nokogiri::XML(xml).xpath(
        '//rif:identifier', ns_decl)
      identifiers = id_nodes.map { |e| e.content.strip }
      having_identifier(*identifiers).first
    end

    # Merge multiple concepts into a single concept containing all their
    # constituent facets.
    def self.merge(concepts)
      primary_concept = concepts.reduce(:merge)

      primary_concept.reload
    end

    # Move another concept's facets to this one, then destroy the empty concept.
    def merge(concept)
      Rails.logger.info("Merging %d facets from concept #%d into #%d" % [
        concept.facets.count,
        concept.id,
        self.id])
      concept.transaction do
        # Transfer concept to primary
        facets = concept.facets.update_all(:concept_id => self.id)
        Rails.logger.info("Removing empty concept #%d" % concept.id)
        concept.reload.destroy
        # Update primary concept details
        self.class.reset_counters(self.id, :facets)
        self.reload.reindex
      end
      self
    end

    # Find duplicate concepts in the system (which may have emerged from
    # identifiers looked up after creation) and merge them together.
    def self.deduplicate
      duplicate_uuids = Miletus::Merge::Concept \
        .group('uuid')\
        .having('count(uuid) > 1')\
        .pluck('uuid')
      duplicate_uuids.each do |uuid|
        self.merge Miletus::Merge::Concept.where(:uuid => uuid)
      end
      duplicate_identifiers = Miletus::Merge::IndexedAttribute \
        .where(:key => 'identifier') \
        .group('value')\
        .having('count(DISTINCT id) > 1')\
        .pluck('value')
      duplicate_identifiers.each do |identifier|
        self.merge(having_identifier(identifier))
      end
    end

    # Generate a RIF-CS representation of this concept based on its consituent
    # facets.
    def to_rif
      rifcs_doc = rifcs_docs.merge
      return nil if rifcs_doc.nil?
      rifcs_doc.group = group
      rifcs_doc.key = key
      rifcs_doc.translate_keys(related_key_dictionary)
      rifcs_doc.root.to_xml(:indent => 2)
    end

    # Repopulated all the cached lookup and description data from this concept's
    # facets.
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

    # Generate a GEXF document representing all existing concepts.
    def self.to_gexf
      GexfDoc.new(self.all).to_xml
    end

    # Generate a GEXF document representing this concept and directly related
    # concepts.
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

    def self.having_identifier(*identifiers)
      existing = identifiers.map do |identifier|
        joins(:indexed_attributes).where(
          IndexedAttribute.table_name.to_sym => {
            :key => 'identifier',
            :value => identifier
          }
        ).pluck(:concept_id)
      end.flatten
      return [] if existing.empty?
      where(:id => existing)
    end

    def generate_uuid
      return unless uuid.nil? and facets.count > 0
      facet_key = facets.first.key
      return if facet_key.nil?
      uuid = uuid_from_facet_key(facet_key).to_s
      # UUIDs are based on the facet key, so merge if identical
      existing_concept = self.class.find_by_uuid(uuid)
      if existing_concept.nil?
        self.uuid = uuid
      else
        self.class.merge([existing_concept, self])
      end
    end

    def uuid_from_facet_key(facet_key)
      begin
        # Assume that the key is a valid URI
        UUIDTools::UUID.sha1_create(
          UUIDTools::UUID_URL_NAMESPACE,
          URI.parse(facet_key).to_s)
      rescue
        # Handle the key not being a valid URI
        UUIDTools::UUID.sha1_create(
          UUIDTools::UUID.parse('00000000-0000-0000-0000-000000000000'),
          facet_key)
      end
    end

    def update_indexed_attributes_from_facet_rifcs
      input_docs = rifcs_docs
      key_xpaths = {
        'identifier' => '//rif:registryObject/rif:*/rif:identifier',
        'relatedKey' => '//rif:relatedObject/rif:key',
        'email'      => '//rif:registryObject/rif:party/rif:location/'+
                        'rif:address/rif:electronic[@type="email"]/rif:value'
      }
      key_xpaths.each do |key, xpath|
        indexed_attributes.update(key, input_docs.content_from_nodes(xpath))
      end
    end

    def recache_attributes
      rifcs_doc = RifcsDoc.create(to_rif)
      self.sort_key = rifcs_doc.sort_key || self.id.to_s
      self.titles = rifcs_doc.titles
      self.type, self.subtype = rifcs_doc.types
      # Key index for faster graph generation
      out_keys = indexed_attributes.where(:key => 'relatedKey').pluck(:value)
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
      ENV.key?('CONCEPT_KEY_PREFIX') ? ENV['CONCEPT_KEY_PREFIX'] : 'urn:uuid:'
    end

    def tn(relation)
      self.class.reflect_on_association(relation).klass.table_name
    end

    def rifcs_docs
      RifcsDocs.new facets.order(:created_at).map(&:to_rif).compact
    end

  end

end