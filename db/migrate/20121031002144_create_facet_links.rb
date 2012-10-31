class CreateFacetLinks < ActiveRecord::Migration
  def up
    create_table :facet_links do |t|
      t.references :facet
      t.references :harvest_record, :polymorphic => true
      t.timestamps
    end
    # Trigger updates so the new links exist
    ( Miletus::Harvest::Atom::RDC::Entry.all +
      Miletus::Harvest::Document::RIFCS.all +
      Miletus::Harvest::OAIPMH::RIFCS::Record.all
    ).each do |record|
      RifcsRecordObserver.instance.after_touch(record)
    end
  end

  def down
    drop_table :facet_links
  end
end
