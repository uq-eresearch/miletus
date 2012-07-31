class CreateOutputOaipmhRecords < ActiveRecord::Migration

  def self.up
    create_table :output_oaipmh_records do |t|
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
      t.text :metadata, :null => false
      t.boolean :deleted, :default => false, :null => false
    end

    create_table :output_oaipmh_indexed_attributes do |t|
      t.references :record
      t.string :key, :null => false
      t.text :value
    end

    add_index(:output_oaipmh_indexed_attributes, [:key, :value])
    add_index(:output_oaipmh_indexed_attributes, [:record_id, :key, :value],
      :name => "index_output_oaipmh_indexed_attributes_row_unique",
      :unique => true)
  end

  def self.down
    drop_table :output_oaipmh_records
  end

end