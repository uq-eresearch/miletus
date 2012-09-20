module Miletus::Output::OAIPMH

  class RecordProvider < OAI::Provider::Base
    repository_name 'Miletus OAI Provider'

    if ENV.has_key? 'ADMIN_EMAIL'
      admin_email ENV['ADMIN_EMAIL']
    else
      require 'etc'
      require 'socket'
      admin_email '%s@%s' % [Etc.getlogin, Socket.gethostname]
    end

    source_model OAI::Provider::ActiveRecordWrapper.new(
      Miletus::Output::OAIPMH::Record
    )
    register_format(RifcsFormat.instance)

    def self.prefix
      "oai:%s" % URI.parse(self.url).host
    end

  end

end