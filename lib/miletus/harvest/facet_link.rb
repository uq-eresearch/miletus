module Miletus::Harvest
  class FacetLink < ActiveRecord::Base

    belongs_to :facet, :class_name => 'Miletus::Merge::Facet',
      :dependent => :destroy
    belongs_to :harvest_record, :polymorphic => true

    attr_accessible :facet

  end
end