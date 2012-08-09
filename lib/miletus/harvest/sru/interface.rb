
module Miletus::Harvest::SRU::Interface
  class Interface < ActiveRecord::Base

    self.table_name = 'sru_interfaces'

    attr_accessible :endpoint

    validates :endpoint, :presence => true
    validates_format_of :endpoint, :with => URI::regexp(%w(http https))
    validates_uniqueness_of :endpoint

  end
end