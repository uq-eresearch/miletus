module Miletus::Merge

  class Facet < ActiveRecord::Base

    self.table_name = 'merge_facets'

    attr_accessible :key, :metadata
    belongs_to :concept, :touch => true

  end

end