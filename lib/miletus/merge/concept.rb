module Miletus::Merge

  class Concept < ActiveRecord::Base

    self.table_name = 'merge_concepts'

    has_many :facets, :dependent => :destroy, :order => 'updated_at DESC'
    has_many :indexed_attributes,
      :dependent => :destroy, :order => [:key, :value]

    def to_rif
      facets.empty? ? nil : facets.first.metadata
    end

  end

end