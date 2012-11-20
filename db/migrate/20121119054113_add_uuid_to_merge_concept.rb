class AddUuidToMergeConcept < ActiveRecord::Migration
  def change
    add_column :merge_concepts, :uuid, :string
    # Reindex to generate UUIDs
    Miletus::Merge::Concept.all.each(&:reindex)
  end
end
