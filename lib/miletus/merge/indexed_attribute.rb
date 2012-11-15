module Miletus::Merge

  class IndexedAttribute < ActiveRecord::Base

    self.table_name = 'merge_indexed_attributes'

    belongs_to :concept, :class_name => 'Miletus::Merge::Concept'
    attr_accessible :concept, :key, :value

    def self.update_for_concept(concept, key, new_values)
      # Handle empty values, which tends to unify completely unrelated facets
      new_values.delete_if {|v| v.nil? or v == ''}
      # Swap in the new values
      concept.transaction do
        current_values = concept.indexed_attributes.where(
          :key => key).pluck(:value)
        (new_values - current_values).each do |v|
          concept.indexed_attributes.find_or_create_by_key_and_value(key, v)
        end
        concept.indexed_attributes.where(
          :key => key,
          :value => current_values - new_values).destroy_all
      end
    end

  end

end