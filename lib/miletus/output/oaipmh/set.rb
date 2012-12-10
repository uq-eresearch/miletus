require 'nokogiri'

module Miletus::Output::OAIPMH

  class Set < ActiveRecord::Base

    self.table_name = 'output_oaipmh_sets'

    attr_accessible :name, :spec, :description
    has_and_belongs_to_many :records,
      :class_name => 'Record',
      :join_table => 'output_oaipmh_record_set_memberships'

  end

end
