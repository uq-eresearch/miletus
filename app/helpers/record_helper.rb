module RecordHelper

  def description(rifcs_doc)
    extend Miletus::NamespaceHelper
    node = rifcs_doc.at_xpath(
      "//rif:description",
      ns_decl)
    node.nil? ? '' : node.content
  end

  def email_addresses(rifcs_doc)
    extend Miletus::NamespaceHelper
    nodes = rifcs_doc.xpath(
      "//rif:location/rif:address/rif:electronic[@type='email']/rif:value",
      ns_decl)
    nodes.map {|e| e.content}
  end

  def email_uris(rifcs_doc)
    email_addresses(rifcs_doc).map do |addr|
      obsfucated_addr = addr.bytes.map{|b| '&#%d;' % b}.join('')
      "mailto:%s" % obsfucated_addr
    end
  end

  def titles(rifcs_doc)
    extend Miletus::NamespaceHelper
    names = rifcs_doc.xpath("//rif:name", ns_decl)
    names.map do |name|
      part_order = ['title', 'given', 'family', 'suffix', nil]
      parts = name.xpath("rif:namePart", ns_decl).to_ary
      parts.delete_if { |part| not part_order.include?(part['type']) }
      parts.sort_by! do |part|
        # In part order, but use original index to sort equal elements
        part_order.index(part['type']) * parts.length + parts.index(part)
      end
      parts.map{|e| e.content}.join(" ")
    end.uniq
  end

  def urls(rifcs_doc)
    extend Miletus::NamespaceHelper
    nodes = rifcs_doc.xpath(
      "//rif:location/rif:address/rif:electronic[@type='url']/rif:value",
      ns_decl)
    nodes.map {|e| e.content}
  end


end
