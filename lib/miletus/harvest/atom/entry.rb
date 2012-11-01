require 'atom'
require 'uri'

module Miletus::Harvest::Atom

  class Entry < ActiveRecord::Base
    extend Forwardable
    include Miletus::NamespaceHelper

    self.table_name = :harvest_atom_entries

    before_validation do
      self.identifier = atom_entry.id
    end

    after_save :update_document_links

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
      :class_name => 'Miletus::Harvest::Atom::Feed'

    has_many :document_links,
      :class_name => 'Miletus::Harvest::Atom::DocumentLink'

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

    def update_document_links
      alt_links = atom_entry.links.alternates
      # Remove disappeared documents
      alt_link_urls = alt_links.map {|l| l.href}
      document_links.reject do |dl|
        alt_link_urls.include?(dl.document.url)
      end.each(&:destroy)
      # Add new documents
      document_link_urls = document_links.map{|dl| document.url}
      alt_links.reject do |l|
        document_link_urls.include?(l.href)
      end.each do |l|
        document = find_or_create_document(l)
        next if document.nil?
        document_link = document_links.create()
        document_link.document = document
        document_link.type = l.type
        document_link.length = l.length
        document_link.save!
      end
      # Update document_links
      document_links.reset
      # Schedule fetch of all documents
      document_links.each do |dl|
        dl.document.delay.fetch
      end
    end

    def find_or_create_document(link)
      model = case link.type
        when 'application/atom+xml'
          Miletus::Harvest::Document::RDCAtom
        when 'application/rifcs+xml'
          Miletus::Harvest::Document::RIFCS
        else
          nil
        end
      return nil if model.nil?
      model.find_or_create_by_url(:url => link.href)
    end

  end

end

