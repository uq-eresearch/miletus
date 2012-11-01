module Miletus::Harvest::Atom

  class DocumentLink < ActiveRecord::Base

    self.table_name = :harvest_atom_entry_documents

    store :info, :accessors => [:type, :length]

    belongs_to :entry, :class_name => 'Miletus::Harvest::Atom::Entry'
    belongs_to :document, :class_name => 'Miletus::Harvest::Document::Base'

  end

end