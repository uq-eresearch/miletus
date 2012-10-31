require 'atom'
require 'digest'
require 'uri'

module Miletus::Harvest::Atom::RDC

  class Entry < ActiveRecord::Base
    extend Forwardable
    include Miletus::NamespaceHelper

    REL_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    REL_ACCESS_RIGHTS = 'http://purl.org/dc/terms/accessRights'
    REL_FAMILY_NAME = 'http://xmlns.com/foaf/0.1/familyName'
    REL_GIVEN_NAME = 'http://xmlns.com/foaf/0.1/givenName'
    REL_MADE = 'http://xmlns.com/foaf/0.1/made'
    REL_MBOX = 'http://xmlns.com/foaf/0.1/mbox'
    REL_OUTPUT_OF = \
      'http://www.ands.org.au/ontologies/ns/0.1/VITRO-ANDS.owl#isOutputOf'
    REL_REFERENCED_BY = 'http://purl.org/dc/terms/isReferencedBy'
    REL_RELATED_WEBSITE = 'http://xmlns.com/foaf/0.1/page'
    REL_SPATIAL = 'http://purl.org/dc/terms/spatial'
    REL_TEMPORAL = 'http://purl.org/dc/terms/temporal'

    self.table_name = :harvest_atom_rdc_entries

    before_validation do
      self.atom_id = atom_entry.id
    end

    attr_accessible :xml

    def_delegators :atom_entry,
      :updated,
      :published,
      :title,
      :summary,
      :authors,
      :contributors,
      :rights,
      :links,
      :source,
      :categories,
      :content,
      :metas

    belongs_to :feed,
      :class_name => 'Miletus::Harvest::Atom::RDC::Feed',
      :counter_cache => :entry_count

    has_many :facet_links, :as => :harvest_record,
      :class_name => 'Miletus::Harvest::FacetLink'

    def atom_entry
      begin
        Atom::Entry.new(XML::Reader.string(xml))
      rescue TypeError # Handle nil string
        Atom::Entry.new()
      end
    end

    def deleted?
      false
    end

    def given_name
      meta = metas.detect {|m| m.property == REL_GIVEN_NAME}
      meta.nil? ? nil : meta.content
    end

    def family_name
      meta = metas.detect {|m| m.property == REL_FAMILY_NAME}
      meta.nil? ? nil : meta.content
    end

    def type
      types.first
    end

    def subtype
      types.last
    end

    def types
      link = links.detect {|l| l.rel == REL_TYPE}
      case link.href
      when 'http://xmlns.com/foaf/0.1/Agent'
        if given_name.nil?
          ['party', 'group']
        else
          ['party', 'person']
        end
      when 'http://purl.org/dc/dcmitype/Dataset'
        ['collection', 'dataset']
      when 'http://purl.org/dc/dcmitype/Collection'
        ['collection', 'collection']
      else
        raise NotImplementedError.new('Unknown Atom RDC type')
      end
    end

    def access_rights
      meta = metas.detect {|m| m.property == REL_ACCESS_RIGHTS}
      meta.nil? ? nil : meta.content
    end

    def license
      links.detect {|l| l.rel == 'license'}
    end

    def category_scheme_to_subject_type(term)
      case term
      when 'http://purl.org/asc/1297.0/2008/for/'
        'anzsrc-for'
      when 'http://purl.org/asc/1297.0/2008/seo/'
        'anzsrc-seo'
      else
        'local'
      end
    end

    def to_rif
      return nil if xml.nil?
      Nokogiri::XML::Builder.new do |xml|
        xml.registryObjects(:xmlns => ns_by_prefix('rif').uri) {
          xml.registryObject(:group => source.title) {
            xml.key(atom_entry.id)
            xml.originatingSource(source.id)
            xml.send(type, :type => subtype) {
              xml.identifier(atom_entry.id, :type => 'uri')
              rifcs_alternate_ids(xml)
              rifcs_name(xml)
              xml.description(content, :type => 'full')
              rifcs_categories(xml)
              rifcs_rights(xml)
              rifcs_mbox_email(xml)
              rifcs_location_url(xml)
              rifcs_temporal(xml)
              rifcs_spatial(xml)
              rifcs_referenced_by_related_info(xml)
              rifcs_author_related_objects(xml)
              rifcs_collection_related_objects(xml)
              rifcs_made_related_objects(xml)
              rifcs_output_of_related_objects(xml)
            }
          }
          rifcs_activities(xml)
          rifcs_authors(xml)
          rifcs_made_collection(xml)
          rifcs_related_collections(xml)
        }
      end.to_xml
    end

    private

    def rifcs_name(xml)
      xml.name(:type => 'primary') {
        case subtype
        when 'person'
          xml.namePart family_name, :type => 'family'
          xml.namePart given_name,  :type => 'given'
        else
          xml.namePart title
        end
      }
    end

    def rifcs_categories(xml)
      categories.each do |category|
        if category.label.nil?
          xml.subject(category.term, :type => 'local')
        else
          xml.subject(category.label,
            :type => category_scheme_to_subject_type(category.scheme),
            :termIdentifier => category.term)
        end
      end
    end

    def rifcs_author_key(author)
      uri_hash = Digest::SHA2.new
      uri_hash << (author.uri || 'mailto:%s' % author.email)
      author_fragment = 'author-%s' % uri_hash.hexdigest
      uri = URI.parse(atom_entry.id)
      if uri.fragment.nil? || uri.fragment.length == 0
        uri.fragment = author_fragment
      else
        uri.fragment += '-%s' % author_fragment
      end
      uri.to_s
    end

    def rifcs_related_key(prefix, href)
      uri_hash = Digest::SHA2.new
      uri_hash << href
      related_fragment = '%s-%s' % [prefix, uri_hash.hexdigest]
      uri = URI.parse(atom_entry.id)
      if uri.fragment.nil? || uri.fragment.length == 0
        uri.fragment = related_fragment
      else
        uri.fragment += '-%s' % related_fragment
      end
      uri.to_s
    end

    def rifcs_author_related_objects(xml)
      authors.each do |author|
        xml.relatedObject {
          xml.key(rifcs_author_key(author))
          xml.relation(:type => 'hasCollector')
        }
      end
    end

    def rifcs_mbox_email(xml)
      email_links = links.select {|l| l.rel == REL_MBOX}
      email_links.each do |link|
        email_address = link.href.partition('mailto:').last
        xml.location {
          xml.address {
            xml.electronic(:type => 'email') {
              xml.value email_address
            }
          }
        }
      end
    end

    def rifcs_made_related_objects(xml)
      output_links = links.select {|l| l.rel == REL_OUTPUT_OF}
      output_links.each do |link|
        xml.relatedObject {
          xml.key(rifcs_related_key('collection', link.href))
          xml.relation(:type => 'isCollectorOf')
        }
      end
    end

    def rifcs_output_of_related_objects(xml)
      output_links = links.select {|l| l.rel == REL_OUTPUT_OF}
      output_links.each do |link|
        xml.relatedObject {
          xml.key(rifcs_related_key('activity', link.href))
          xml.relation(:type => 'isOutputOf')
        }
      end
    end

    def rifcs_collection_related_objects(xml)
      related_links = links.select {|l| l.rel == 'related'}
      related_links.each do |link|
        xml.relatedObject {
          xml.key(rifcs_related_key('collection', link.href))
          xml.relation(:type => 'hasAssociationWith')
        }
      end
    end

    def rifcs_alternate_ids(xml)
      links.alternates.each do |link|
        xml.identifier(link.href, :type => 'uri')
      end
    end

    def rifcs_location_url(xml)
      related_links = links.select {|l| l.rel == REL_RELATED_WEBSITE}
      related_links.each do |link|
        xml.location {
          xml.address {
            xml.electronic(:type => 'url') {
              xml.value link.href
            }
          }
        }
      end
    end

    # From:
    # ```
    # <rdfa:meta
    #    property="http://purl.org/dc/terms/temporal"
    #    content="start=2006;end=2007;" />
    # ```
    #
    # To:
    # ```
    # <coverage>
    #    <temporal>
    #       <date type="dateFrom" dateFormat="W3CDTF">2006</date>
    #       <date type="dateTo" dateFormat="W3CDTF">2007</date>
    #    </temporal>
    # </coverage>
    # ```
    def rifcs_temporal(xml)
      translation = {'start' => 'dateFrom', 'end' => 'dateTo'}
      temporal_coverage = self.metas.select {|m| m.property == REL_TEMPORAL}
      temporal_coverage.each do |meta|
        xml.coverage {
          xml.temporal {
            meta.content.split(';').each do |chunk|
              k, _, v = chunk.partition('=')
              next unless translation.key?(k)
              xml.date(v, :dateFormat => 'W3CDTF', :type => translation[k])
            end
          }
        }
      end
    end

    # From:
    # ```
    # <georss:polygon>-9.3985000000002 143.4947 ...</georss:polygon>
    # <link href="http://www.geonames.org/2077456/"
    #       rel="http://purl.org/dc/terms/spatial"
    #       title="Australia" />
    # ```
    #
    # To:
    #
    # ```
    # <coverage>
    #    <spatial type="kmlPolyCoords">143.4947,-9.3985000000002 ...
    #    </spatial>
    # </coverage>
    # <coverage>
    #    <spatial type="dcmiPoint">
    #      east=135.0; north=-25.0; name=Australia
    #    </spatial>
    # </coverage>
    # ```
    def rifcs_spatial(xml)
      self.atom_entry.georss_polygons.each do |polygon|
        xml.coverage {
          xml.spatial polygon.rings.first.kml_poslist({}),
            :type => 'kmlPolyCoords'
        }
      end
      spatial_links = links.select {|l| l.rel == REL_SPATIAL}
      unless spatial_links.empty?
        require 'open-uri'
        spatial_links.each do |link|
          begin
            html = Nokogiri::HTML(URI.parse(link.href).read)
            coords = html.at_xpath('//meta[@name="geo.position"]')
            if coords.nil?
              raise Exception.new('Unable to get position from URL')
            end
            north, _, east = coords['content'].partition(';')
            dcmi_point = "east=#{east}; north=#{north}"
            dcmi_point += "; name=#{link.title}" unless link.title.nil?
            xml.coverage {
              xml.spatial dcmi_point, :type => 'dcmiPoint'
            }
          rescue
            unless link.title.nil? or link.title == ''
              xml.coverage {
                xml.spatial link.title, :type => 'text'
              }
            end
          end
        end
      end
    end

    def rifcs_referenced_by_related_info(xml)
      reference_links = links.select {|l| l.rel == REL_REFERENCED_BY}
      reference_links.each do |link|
        xml.relatedInfo(:type => 'publication') {
          xml.identifier(link.href, :type => 'uri')
          xml.title(link.title) unless link.title.nil?
        }
      end
    end

    def rifcs_authors(xml)
      authors.each do |author|
        xml.registryObject(:group => source.title) {
          xml.key(rifcs_author_key(author))
          xml.originatingSource(source.id)
          xml.party(:type => 'group') {
            xml.identifier(author.uri, :type => 'uri')
            xml.name(:type => 'primary') {
              xml.namePart(author.name)
            } unless author.name.nil?
            xml.location {
              xml.address {
                xml.electronic(:type => 'email') {
                  xml.value(author.email)
                }
              }
            } unless author.email.nil?
            xml.relatedObject {
              xml.key(atom_entry.id)
              xml.relation(:type => 'isCollectorOf')
            }
          }
        }
      end
    end

    def rifcs_activities(xml)
      output_links = links.select {|l| l.rel == REL_OUTPUT_OF}
      output_links.each do |link|
        xml.registryObject(:group => source.title) {
          xml.key(rifcs_related_key('activity', link.href))
          xml.originatingSource(source.id)
          xml.activity(:type => 'project') {
            xml.identifier(link.href, :type => 'uri')
            xml.name(:type => 'primary') {
              xml.namePart(link.title)
            } unless link.title.nil?
            xml.relatedObject {
              xml.key(atom_entry.id)
              xml.relation(:type => 'hasOutput')
            }
          }
        }
      end
    end

    def rifcs_made_collection(xml)
      made_links = links.select {|l| l.rel == REL_MADE}
      made_links.each do |link|
        xml.registryObject(:group => source.title) {
          xml.key(rifcs_related_key('collection', link.href))
          xml.originatingSource(source.id)
          xml.collection(:type => 'group') {
            xml.identifier(link.href, :type => 'uri')
            xml.name(:type => 'primary') {
              xml.namePart(link.title)
            } unless link.title.nil?
            xml.relatedObject {
              xml.key(atom_entry.id)
              xml.relation(:type => 'hasCollector')
            }
          }
        }
      end
    end

    def rifcs_related_collections(xml)
      related_links = links.select {|l| l.rel == 'related'}
      related_links.each do |link|
        xml.registryObject(:group => source.title) {
          xml.key(rifcs_related_key('collection', link.href))
          xml.originatingSource(source.id)
          xml.collection(:type => 'group') {
            xml.identifier(link.href, :type => 'uri')
            xml.name(:type => 'primary') {
              xml.namePart(link.title)
            } unless link.title.nil?
            xml.relatedObject {
              xml.key(atom_entry.id)
              xml.relation(:type => 'hasAssociationWith')
            }
          }
        }
      end
    end

    def rifcs_rights(xml)
      xml.rights {
        xml.accessRights(access_rights) unless access_rights.nil?
        unless license.nil?
          xml.licence(license.title, :rightsUri => license.href)
        end
        xml.rightsStatement(rights) unless rights.nil?
      } unless [access_rights, license, rights].all?(&:nil?)
    end

  end

end

