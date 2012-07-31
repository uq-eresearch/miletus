class CreateMergeConceptFacets < ActiveRecord::Migration

  def self.up

    create_table :merge_concepts do |t|
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
    end

    create_table :merge_facets do |t|
      t.references :concept
      t.string   :key
      t.text     :metadata
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
    end

    create_table :merge_indexed_attributes do |t|
      t.references :concept
      t.string :key, :null => false
      t.text :value
    end

    add_index(:merge_indexed_attributes, [:key, :value])
    add_index(:merge_indexed_attributes, [:concept_id, :key, :value],
      :unique => true)

  end

  def self.down
    drop_table :merge_indexed_attributes
    drop_table :merge_facet
    drop_table :merge_concept
  end

end