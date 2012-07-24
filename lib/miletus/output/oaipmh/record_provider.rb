module Miletus::Output::OAIPMH

  class RecordProvider < OAI::Provider::Base
    repository_name 'Miletus OAI Provider'
    admin_email 'root@localhost'
    source_model OAI::Provider::ActiveRecordWrapper.new(
      Miletus::Output::OAIPMH::Record
    )
    register_format(RifcsFormat.instance)

    def self.prefix
      "oai:%s" % URI.parse(self.url).host
    end

  end

end