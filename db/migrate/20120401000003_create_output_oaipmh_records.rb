class CreateOutputOaipmhRecords < ActiveRecord::Migration

  def self.up
    create_table :output_oaipmh_records do |t|
      t.references  :underlying_concept
      t.references  :set_memberships
      t.text        :metadata
      t.datetime    :created_at, :null => false
      t.datetime    :updated_at, :null => false
    end

    create_table :output_oaipmh_sets do |t|
      t.references  :set_memberships
      t.string      :spec, :null => false
      t.string      :name, :null => false
      t.string      :description
      t.datetime    :created_at, :null => false
      t.datetime    :updated_at, :null => false
    end

    create_table :output_oaipmh_record_set_memberships do |t|
      t.references  :record
      t.references  :set
    end

  end

  def self.down
    drop_table :output_oaipmh_set_memberships
    drop_table :output_oaipmh_records
    drop_table :output_oaipmh_sets
  end

end