class AddFacetsCountToMergeConcepts < ActiveRecord::Migration
  def change
    add_column :merge_concepts, :facets_count, :integer
  end
end
