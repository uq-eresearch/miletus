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
              '/documentation/rifcs/schema/registryObjects.xsd'),
          Namespace.new('http://www.gexf.net/1.2draft',
            'gexf', 'http://gexf.net/1.2draft/gexf.xsd'),
          Namespace.new('http://www.sitemaps.org/schemas/sitemap/0.9',
            'sitemap',
            'http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd'),
          Namespace.new('http://www.sitemaps.org/schemas/sitemap/0.9',
            'siteindex',
            'http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd')
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

  # Mixin module which can be used to avoid direct use of "ns_decl" helper
  module XPathNamespaceMixin
    include Miletus::NamespaceHelper

    # :at_xpath with namespace definitions
    def at_xpath(*paths)
      if paths.last.is_a? Hash
        super(*paths)
      else
        super(*paths, ns_decl)
      end
    end

    # :at_xpath with namespace definitions
    def xpath(*paths)
      if paths.last.is_a? Hash
        super(*paths)
      else
        super(*paths, ns_decl)
      end
    end
  end
end