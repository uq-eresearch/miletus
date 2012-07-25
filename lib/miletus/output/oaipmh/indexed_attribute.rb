module Miletus::Output::OAIPMH

  class IndexedAttribute < ActiveRecord::Base

    self.table_name = 'output_oaipmh_indexed_attributes'

    belongs_to :record, :class_name => 'Miletus::Output::OAIPMH::Record'

    attr_accessible :key, :value

  end

end