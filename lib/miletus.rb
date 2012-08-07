require 'active_record'
require 'oai'
require 'time'
require 'xml/libxml'

module Miletus
  module NamespaceHelper
    @@namespaces = [
      { :prefix => 'oai',
        :schema => 'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd',
        :uri => 'http://www.openarchives.org/OAI/2.0/' },
      { :prefix => 'oaii',
        :schema => 'http://www.openarchives.org/OAI/2.0/oai-identifier.xsd',
        :uri => 'http://www.openarchives.org/OAI/2.0/oai-identifier' },
      { :prefix => 'dc',
        :schema => 'http://dublincore.org/schemas/xmls/simpledc20021212.xsd',
        :uri => 'http://purl.org/dc/elements/1.1/' },
      { :prefix => 'oai_dc',
        :schema => 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd',
        :uri => 'http://www.openarchives.org/OAI/2.0/oai_dc/' },
      { :prefix => 'rif',
        :schema => 'http://services.ands.org.au' +
          '/documentation/rifcs/schema/registryObjects.xsd',
        :uri => 'http://ands.org.au/standards/rif-cs/registryObjects' }
    ]

    def schema_by_prefix(prefix)
      (ns_obj = namespace_by(:prefix, prefix)) && fetch_schema_object(ns_obj)
    end

    def ns_decl
      # Convenience definition for XPath matching
      @@namespaces.each_with_object({}) do |h, obj|
        obj[h[:prefix]] = h[:uri]
      end
    end

    module_function :schema_by_prefix
    module_function :ns_decl

    private

    def namespace_by(key, value)
      idx = @@namespaces.index { |obj| obj[key] == value }
      idx.nil? ? nil : @@namespaces[idx]
    end

    def fetch_schema_object(ns_obj)
      ns_obj[:schema_obj] ||= build_schema_object(ns_obj[:schema])
    end

    def build_schema_object(schema_loc)
      require 'open-uri'
      schema_doc = Nokogiri::XML(open(schema_loc), url = schema_loc)
      Nokogiri::XML::Schema.from_document(schema_doc)
    end

  end

  require File.join(File.dirname(__FILE__), 'miletus', 'harvest')
  require File.join(File.dirname(__FILE__), 'miletus', 'merge')
  require File.join(File.dirname(__FILE__), 'miletus', 'output')
end