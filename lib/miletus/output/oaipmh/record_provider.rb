require 'oai'
require 'miletus/harvest/oaipmh_rifcs/record'
require File.dirname(__FILE__)+'/rifcs_format'

module Miletus
  module Output
    module OAIPMH

      class RecordProvider < OAI::Provider::Base
        repository_name 'Miletus OAI Provider'
        repository_url 'http://localhost:3000/oai'
        admin_email 'root@localhost'
        source_model OAI::Provider::ActiveRecordWrapper.new(
          Miletus::Harvest::OAIPMH::RIFCS::Record,
          :timestamp_field => 'datestamp'
        )
        register_format(RifcsFormat.instance)
      end

    end
  end
end