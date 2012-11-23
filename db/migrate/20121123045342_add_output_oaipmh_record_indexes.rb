class AddOutputOaipmhRecordIndexes < ActiveRecord::Migration

  def change
    add_index :output_oaipmh_record_set_memberships, :record_id
    add_index :output_oaipmh_record_set_memberships, :set_id
  end

end
