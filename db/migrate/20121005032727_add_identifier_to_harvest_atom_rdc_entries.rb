class AddIdentifierToHarvestAtomRdcEntries < ActiveRecord::Migration
  def change
    add_column :harvest_atom_rdc_entries, :atom_id, :string
  end
end
