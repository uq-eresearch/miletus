class CreateOaipmhRifcsRecordCollections < ActiveRecord::Migration

  def self.up
    create_table :oaipmh_rifcs_record_collections do |t|
      t.string :endpoint, :null => false
    end

    create_table :oaipmh_rifcs_records do |t|
      t.references :record_collection
      t.string :identifier, :null => false
      t.datetime :datestamp, :null => false
      t.text :metadata, :null => false
      t.boolean :deleted, :default => false, :null => false
    end
  end

  def self.down
    drop_table :oaipmh_rifcs_records
    drop_table :oaipmh_rifcs_record_collections
  end

end