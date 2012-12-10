class RemoveUnnecessaryOaipmhOutputColumns < ActiveRecord::Migration
  def change
    remove_column :output_oaipmh_records, :set_memberships_id
    remove_column :output_oaipmh_sets, :set_memberships_id
  end
end
