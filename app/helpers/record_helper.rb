module RecordHelper

  def annotated_xml(rifcs_doc)
    # HTML escape, then convert SafeBuffer to String so `gsub` works OK
    xml = html_escape(rifcs_doc.to_xml).to_str
    xml = xml.gsub(/&lt;key&gt;(\S+)&lt;\/key&gt;/) do |s|
      begin
        (html_escape("<key>%s</key>").to_str) %
          ('<strong><a href="%s">%s</a></strong>' % [concept_path($1), $1])
      rescue
        (html_escape("<key>%s</key>").to_str) % $1
      end
    end
    xml.html_safe
  end

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

  def urls(rifcs_doc)
    extend Miletus::NamespaceHelper
    nodes = rifcs_doc.xpath(
      "//rif:location/rif:address/rif:electronic[@type='url']/rif:value",
      ns_decl)
    nodes.map {|e| e.content}
  end


end
