class AddSortKeyToMergeConcept < ActiveRecord::Migration
  def change
    add_column :merge_concepts, :sort_key, :string
  end
end
