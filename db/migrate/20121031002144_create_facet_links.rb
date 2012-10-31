class CreateFacetLinks < ActiveRecord::Migration
  def up
    create_table :facet_links do |t|
      t.references :facet
      t.references :harvest_record, :polymorphic => true
      t.timestamps
    end
  end

  def down
    drop_table :facet_links
  end
end
