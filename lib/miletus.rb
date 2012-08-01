require 'active_record'
require 'oai'
require 'time'
require 'xml/libxml'

module Miletus
  module NamespaceHelper
    def ns_decl
      # Convenience definition for XPath matching
      {
        'oai' => 'http://www.openarchives.org/OAI/2.0/',
        'oaii' => 'http://www.openarchives.org/OAI/2.0/oai-identifier',
        'dc' => 'http://purl.org/dc/elements/1.1/',
        'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
        'rif' => 'http://ands.org.au/standards/rif-cs/registryObjects'
      }
    end
    module_function :ns_decl
  end

  require File.join(File.dirname(__FILE__), 'miletus', 'harvest')
  require File.join(File.dirname(__FILE__), 'miletus', 'merge')
  require File.join(File.dirname(__FILE__), 'miletus', 'output')
end