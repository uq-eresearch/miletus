require 'active_record'
require 'oai'
require 'time'
require 'xml/libxml'

module Miletus
  module NamespaceHelper

    class Namespace < Struct.new(:uri, :prefix, :schema_location)

      def self.instances
        @@instances ||= [
          Namespace.new('http://www.openarchives.org/OAI/2.0/',
            'oai', 'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd'),
          Namespace.new('http://www.openarchives.org/OAI/2.0/oai-identifier',
            'oaii', 'http://www.openarchives.org/OAI/2.0/oai-identifier.xsd'),
          Namespace.new('http://purl.org/dc/elements/1.1/',
            'dc', 'http://dublincore.org/schemas/xmls/simpledc20021212.xsd'),
          Namespace.new('http://www.openarchives.org/OAI/2.0/oai_dc/',
            'oai_dc', 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'),
          Namespace.new('http://ands.org.au/standards/rif-cs/registryObjects',
            'rif','http://services.ands.org.au' +
              '/documentation/rifcs/schema/registryObjects.xsd')
        ]
      end

      def schema
        @schema_obj ||= build_schema_object
      end

      private

      def build_schema_object
        require 'open-uri'
        schema_doc = Nokogiri::XML(open(schema_location), url = schema_location)
        Nokogiri::XML::Schema.from_document(schema_doc)
      end

    end

    # Lookup on
    Namespace.members.each do |key|
      method_sym = ("ns_by_%s" % key).to_sym
      define_method(method_sym) do |value|
        Namespace.instances.find { |obj| obj.send(key) == value }
      end
      module_function method_sym
    end

    def ns_decl
      # Convenience definition for XPath matching
      Namespace.instances.each_with_object({}) do |ns, obj|
        obj[ns.prefix] = ns.uri
      end
    end

    module_function :ns_decl

  end

  require File.join(File.dirname(__FILE__), 'miletus', 'harvest')
  require File.join(File.dirname(__FILE__), 'miletus', 'merge')
  require File.join(File.dirname(__FILE__), 'miletus', 'output')
end