class AddSetToOaipmhRifcsRecordCollections < ActiveRecord::Migration
  def change
    add_column :oaipmh_rifcs_record_collections, :set, :string
  end
end
