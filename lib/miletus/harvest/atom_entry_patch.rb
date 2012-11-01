require 'atom'
require 'delegate'

Atom::Entry.class_eval do

  class Atom::Entry::RdfaMeta
    include Atom::Xml::Parseable

    attribute :content
    uri_attribute :property

    def initialize(o)
      case o
      when XML::Reader
        valid_e = [Atom::NAMESPACE, 'http://www.w3.org/ns/rdfa#'].any? do |ns|
          current_node_is?(o, 'meta', ns)
        end
        if valid_e
          parse(o, :once => true)
        else
          raise ArgumentError,
            "Meta created with node other than rdfa:meta: [%s,%s]" %
            [o.namespace_uri, o.name]
        end
      when Hash
        [:content, :property].each do |attr|
          self.send("#{attr}=", o[attr])
        end
      else
        raise ArgumentError, "Don't know how to handle #{o}"
      end
    end

  end

  known_namespaces << 'http://www.w3.org/ns/rdfa#'

  elements 'metas', :class => Atom::Entry::RdfaMeta

  element 'rights'

  def georss_polygons
    require 'geo_ruby'
    require 'geo_ruby/georss'
    require 'geo_ruby/simple_features/polygon'
    k = '{http://www.georss.org/georss,polygon}'
    return [] unless @simple_extensions.key? k
    @simple_extensions[k].map do |point_string|
      GeoRuby::SimpleFeatures::Geometry.from_georss(
        '<g:polygon>%s</g:polygon>' % point_string)
    end
  end

end