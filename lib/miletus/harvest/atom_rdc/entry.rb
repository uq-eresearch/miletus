require 'atom'

module Miletus::Harvest::Atom::RDC

  class Entry < ActiveRecord::Base
    extend Forwardable

    self.table_name = :harvest_atom_rdc_entries

    attr_accessible :xml

    def_delegators :atom_entry,
      :id,
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
      :content

    belongs_to :feed,
      :class_name => 'Miletus::Harvest::Atom::RDC::Feed',
      :counter_cache => :entry_count

    def atom_entry
      Atom::Entry.new(XML::Reader.string(xml))
    end

  end

end