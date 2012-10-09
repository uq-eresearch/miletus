require 'atom'

module Miletus::Harvest::Atom::RDC

  class Entry < ActiveRecord::Base
    extend Forwardable
    include Miletus::NamespaceHelper

    REL_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    REL_ACCESS_RIGHTS = 'http://purl.org/dc/terms/accessRights'
    REL_FAMILY_NAME = 'http://xmlns.com/foaf/0.1/familyName'
    REL_GIVEN_NAME = 'http://xmlns.com/foaf/0.1/givenName'

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

    def atom_entry
      Atom::Entry.new(XML::Reader.string(xml))
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
      Nokogiri::XML::Builder.new do |xml|
        xml.registryObjects(:xmlns => ns_by_prefix('rif').uri) {
          xml.registryObject(:group => source.title) {
            xml.key(atom_entry.id)
            xml.originatingSource(source.id)
            xml.send(type, :type => subtype) {
              xml.identifier(atom_entry.id, :type => 'uri')
              rifcs_name(xml)
              xml.description(content, :type => 'full')
              rifcs_categories(xml)
              rifcs_rights(xml)
            }
          }
          rifcs_authors(xml)
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

    def rifcs_authors(xml)
      authors.each do |author|
        xml.registryObject(:group => source.title) {
          xml.key(author.uri || "mailto:%s" % author.email)
          xml.originatingSource(source.id)
          xml.party(:type => 'group') {
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
      }
    end

  end

end

