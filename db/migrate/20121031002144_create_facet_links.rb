class CreateFacetLinks < ActiveRecord::Migration
  def up
    create_table :facet_links do |t|
      t.references :facet
      t.references :harvest_record, :polymorphic => true
      t.timestamps
    end
    # Trigger updates so the new links exist
    Miletus::Harvest::Atom::RDC::Entry.all(&:touch)
    Miletus::Harvest::Document::RIFCS.all(&:touch)
    Miletus::Harvest::OAIPMH::RIFCS::Record.all(&:touch)
  end

  def down
    drop_table :facet_links
  end
end
