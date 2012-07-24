module Miletus::Harvest::OAIPMH
  module RIFCS

    def jobs
      RecordCollection.find(:all).map { |rc| Consumer.new(rc) }
    end

    module_function :jobs

    require File.join(File.dirname(__FILE__),'oaipmh_rifcs','consumer')
    require File.join(File.dirname(__FILE__),'oaipmh_rifcs','record_collection')
    require File.join(File.dirname(__FILE__),'oaipmh_rifcs','record')
  end
end