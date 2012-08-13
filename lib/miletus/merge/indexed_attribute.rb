module Miletus::Merge

  class IndexedAttribute < ActiveRecord::Base

    self.table_name = 'merge_indexed_attributes'

    belongs_to :concept, :class_name => 'Miletus::Output::OAIPMH::Record'
    attr_accessible :concept, :key, :value

  end

end