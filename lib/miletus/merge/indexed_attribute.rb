module Miletus::Merge

  class IndexedAttribute < ActiveRecord::Base

    self.table_name = 'merge_indexed_attributes'

    belongs_to :concept, :class_name => 'Miletus::Output::OAIPMH::Record'
    attr_accessible :concept, :key, :value

    def to_s
      "#{key}: #{value} => #{concept_id}"
    end

  end

end