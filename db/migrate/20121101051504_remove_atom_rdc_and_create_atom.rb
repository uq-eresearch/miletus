class RemoveAtomRdcAndCreateAtom < ActiveRecord::Migration
  def change
    drop_table :harvest_atom_rdc_feeds
    drop_table :harvest_atom_rdc_entries

    create_table :harvest_atom_feeds do |t|
      t.string :url
      t.timestamps
    end

    create_table :harvest_atom_entries do |t|
      t.references :feed
      t.string :identifier
      t.string :updated
      t.text   :xml
      t.timestamps
    end

    create_table :harvest_atom_entry_documents do |t|
      t.references :entry
      t.references :document
      t.text       :info
      t.timestamps
    end

    # Add column to distinguish between user-created and managed documents
    add_column :harvest_documents, :managed, :boolean, { :default => false }
    # Reset column info for unit tests
    Miletus::Harvest::Document::Base.reset_column_information

  end
end
