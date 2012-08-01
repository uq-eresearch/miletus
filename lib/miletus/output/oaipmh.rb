module Miletus::Output::OAIPMH

  RIFCS_KEY_PREFIX = ENV['RIFCS_KEY_PREFIX'] or ''

  require File.join(File.dirname(__FILE__), 'oaipmh', 'record')
  require File.join(File.dirname(__FILE__), 'oaipmh', 'rifcs_format')
  require File.join(File.dirname(__FILE__), 'oaipmh', 'record_provider')
end
