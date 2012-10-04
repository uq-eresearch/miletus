class CreateHarvestAtomRdcFeeds < ActiveRecord::Migration
  def up
    create_table :harvest_atom_rdc_feeds do |t|
      t.string  :url, :null => false
      t.integer :entry_count
    end

    create_table :harvest_atom_rdc_entries do |t|
      t.references :feed
      t.text :xml
    end
  end

  def down
    drop_table :harvest_atom_rdc_feeds
  end
end
