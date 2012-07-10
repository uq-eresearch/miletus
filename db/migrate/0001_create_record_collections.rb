class CreateRecordCollections < ActiveRecord::Migration

  def self.up
    create_table :record_collections do |t|
      t.string :format, :null => false
      t.string :endpoint, :null => false
    end

    create_table :records do |t|
      t.references :record_collection
      t.string :identifier, :null => false
      t.datetime :datestamp, :null => false
      t.text :metadata, :null => false
      t.boolean :deleted, :default => false, :null => false
    end
  end

  def self.down
    drop_table :records
    drop_table :record_collections
  end

end