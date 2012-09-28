class AddMergeConceptCache < ActiveRecord::Migration

  def self.up
    add_column :merge_concepts, :cache, :text
  end

  def self.down
    remove_column :merge_concepts, :cache
  end

end