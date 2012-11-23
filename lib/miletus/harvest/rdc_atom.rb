require 'atom'
require 'digest'
require 'uri'

module Miletus::Harvest::RDCAtom

  class Feed < Struct.new(:atom_feed)
    include Miletus::NamespaceHelper

    def to_rif
      return nil if atom_feed.entries.empty?
      Nokogiri::XML::Builder.new do |xml|
        xml.registryObjects(:xmlns => ns_by_prefix('rif').uri) {
          # Enumerate through remote entries
          atom_feed.entries.each do |e|
            xml << Miletus::Harvest::RDCAtom::Entry.new(e).to_rif
          end
        }
      end.to_xml
    end

  end

  class Entry < Struct.new(:atom_entry)
    extend Forwardable
    include Miletus::NamespaceHelper

    REL_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    REL_ACCESS_RIGHTS = 'http://purl.org/dc/terms/accessRights'
    REL_DESCRIBES = 'http://www.openarchives.org/ore/terms/describes'
    REL_FAMILY_NAME = 'http://xmlns.com/foaf/0.1/familyName'
    REL_GIVEN_NAME = 'http://xmlns.com/foaf/0.1/givenName'
    REL_TITLE = 'http://xmlns.com/foaf/0.1/title'
    REL_MADE = 'http://xmlns.com/foaf/0.1/made'
    REL_MBOX = 'http://xmlns.com/foaf/0.1/mbox'
    REL_OUTPUT_OF = \
      'http://www.ands.org.au/ontologies/ns/0.1/VITRO-ANDS.owl#isOutputOf'
    REL_PUBLISHER = 'http://purl.org/dc/terms/publisher'
    REL_REFERENCED_BY = 'http://purl.org/dc/terms/isReferencedBy'
    REL_RELATED_WEBSITE = 'http://xmlns.com/foaf/0.1/page'
    REL_SPATIAL = 'http://purl.org/dc/terms/spatial'
    REL_TEMPORAL = 'http://purl.org/dc/terms/temporal'

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

    def deleted?
      false
    end

    def name_title
      meta_content_with_property(REL_TITLE)
    end

    def given_name
      meta_content_with_property(REL_GIVEN_NAME)
    end

    def family_name
      meta_content_with_property(REL_FAMILY_NAME)
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
      when 'http://xmlns.com/foaf/0.1/Person'
        ['party', 'person']
      when 'http://purl.org/dc/dcmitype/Dataset'
        ['collection', 'dataset']
      when 'http://purl.org/dc/dcmitype/Collection'
        ['collection', 'collection']
      else
        raise NotImplementedError.new('Unknown Atom RDC type: #{link.inspect}')
      end
    end

    def access_rights
      meta_content_with_property(REL_ACCESS_RIGHTS)
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

    def to_rif(wrap = false)
      return nil if atom_entry.nil?
      builder = Nokogiri::XML::Builder.new do |xml|
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
              rifcs_publisher_related_objects(xml)
              rifcs_collection_related_objects(xml)
              rifcs_made_related_objects(xml)
              rifcs_output_of_related_objects(xml)
            }
          }
          rifcs_activities(xml)
          rifcs_authors(xml)
          rifcs_publishers(xml)
          rifcs_made_collection(xml)
          rifcs_related_collections(xml)
        }
      end
      if wrap
        builder.to_xml
      else
        builder.doc.root.children.to_xml
      end
    end

    private

    def rifcs_name(xml)
      xml.name(:type => 'primary') {
        case subtype
        when 'person'
          nameParts = {
            'title' => name_title,
            'family' => family_name,
            'given' => given_name
          }
          nameParts.each do |k, v|
            xml.namePart(v, :type => k) if v
          end
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

    def rifcs_synthetic_key(type, uri)
      uri_hash = Digest::SHA2.new
      uri_hash << uri.to_s
      synthetic_key_fragment = '%s-%s' % [type, uri_hash.hexdigest]
      uri = URI.parse(atom_entry.id)
      if uri.fragment.nil? || uri.fragment.length == 0
        uri.fragment = synthetic_key_fragment
      else
        uri.fragment += '-%s' % synthetic_key_fragment
      end
      uri.to_s
    end

    def rifcs_author_key(author)
      rifcs_synthetic_key('author', author.uri || 'mailto:%s' % author.email)
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

    def rifcs_publisher_related_objects(xml)
      publisher_links = links.select {|l| l.rel == REL_PUBLISHER}
      publisher_links.each do |l|
        xml.relatedObject {
          xml.key(rifcs_synthetic_key('publisher', l.href))
          xml.relation(:type => 'isManagedBy')
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
      links.select{|l| l.rel == REL_DESCRIBES}.each do |link|
        xml.identifier(link.href, :type => 'uri')
      end
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
            meta.content.split(/\s*;\s*/).each do |chunk|
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
          rescue Exception
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
            xml.identifier(author.uri, :type => 'uri') unless author.uri.nil?
            unless author.email.nil?
              xml.identifier("mailto:#{author.email}", :type => 'uri')
            end
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

    def rifcs_publishers(xml)
      publisher_links = links.select {|l| l.rel == REL_PUBLISHER}
      publisher_links.each do |l|
        xml.registryObject(:group => source.title) {
          xml.key rifcs_synthetic_key('publisher', l.href)
          xml.originatingSource source.id
          xml.party(:type => 'group') {
            xml.identifier(l.href, :type => 'uri')
            xml.name(:type => 'primary') {
              xml.namePart(l.title)
            } if l.title
            xml.relatedObject {
              xml.key(atom_entry.id)
              xml.relation(:type => 'isManagerOf')
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

    def meta_content_with_property(property)
      meta = metas.detect {|m| m.property == property}
      meta.try(:content)
    end

  end

end
