module Miletus::Merge

  class IndexedAttribute < ActiveRecord::Base

    self.table_name = 'merge_indexed_attributes'

    belongs_to :concept, :class_name => 'Miletus::Merge::Concept'
    attr_accessible :concept, :key, :value

  end

end