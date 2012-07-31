class CreateOutputOaipmhRecords < ActiveRecord::Migration

  def self.up
    create_table :output_oaipmh_records do |t|
      t.references  :underlying_concept
      t.text        :metadata
      t.datetime    :created_at, :null => false
      t.datetime    :updated_at, :null => false
    end
  end

  def self.down
    drop_table :output_oaipmh_records
  end

end