class CreateOutputOaipmhRecords < ActiveRecord::Migration

  def self.up
    create_table :output_oaipmh_records do |t|
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
      t.text :metadata, :null => false
      t.boolean :deleted, :default => false, :null => false
    end
  end

  def self.down
    drop_table :output_oaipmh_records
  end

end