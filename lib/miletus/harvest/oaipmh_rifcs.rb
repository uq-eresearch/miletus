require 'miletus/harvest/oaipmh_rifcs/consumer'
require 'miletus/harvest/oaipmh_rifcs/record_collection'

module Miletus
  module Harvest
    module OAIPMH
      module RIFCS

        def jobs
          RecordCollection.find(:all).map { |rc| Consumer.new(rc) }
        end

        module_function :jobs

      end
    end
  end
end