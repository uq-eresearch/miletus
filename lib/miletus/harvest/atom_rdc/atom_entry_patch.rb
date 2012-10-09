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

end