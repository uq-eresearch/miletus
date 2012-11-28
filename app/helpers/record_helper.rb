require 'memoize'

module RecordHelper
  extend Memoize

  def href_from_key(key)
    uuid = key.partition(Miletus::Merge::Concept.key_prefix).last
    concept_path(uuid)
  end

  def annotated_xml(rifcs_doc)
    # HTML escape, then convert SafeBuffer to String so `gsub` works OK
    xml = html_escape(rifcs_doc.to_xml).to_str
    xml = xml.gsub(/&lt;key&gt;(\S+)&lt;\/key&gt;/) do |s|
      begin
        (html_escape("<key>%s</key>").to_str) %
          ('<strong><a href="%s">%s</a></strong>' % [href_from_key($1), $1])
      rescue
        (html_escape("<key>%s</key>").to_str) % $1
      end
    end
    xml.html_safe
  end

  def description(rifcs_doc)
    node = ensure_rifcs_doc(rifcs_doc).at_xpath "//rif:description"
    node ? node.content : ''
  end

  def email_addresses(rifcs_doc)
    extend Miletus::NamespaceHelper
    nodes = ensure_rifcs_doc(rifcs_doc).xpath(
      "//rif:location/rif:address/rif:electronic[@type='email']/rif:value")
    nodes.map {|e| e.content}
  end

  def email_uris(rifcs_doc)
    email_addresses(rifcs_doc).map do |addr|
      obsfucated_addr = addr.bytes.map{|b| '&#%d;' % b}.join('')
      "mailto:%s" % obsfucated_addr
    end.uniq
  end

  def physical_addresses(rifcs_doc)
    extend Miletus::NamespaceHelper
    addrs = ensure_rifcs_doc(rifcs_doc).xpath(
      "//rif:location/rif:address/rif:physical")
    addrs.map do |address|
      nodes = address.xpath("rif:addressPart", ns_decl)
      type_content_map(nodes)
    end
  end

  def related_info(rifcs_doc)
    extend Miletus::NamespaceHelper
    ensure_rifcs_doc(rifcs_doc).xpath(
      "//rif:relatedInfo[rif:identifier/@type='uri']").map do |info|
      OpenStruct.new node_children_and_attributes(info)
    end.sort_by(&:title)
  end

  def rights(rifcs_doc)
    extend Miletus::NamespaceHelper
    rights = ensure_rifcs_doc(rifcs_doc).at_xpath "//rif:rights"
    return nil if rights.nil?
    nodes = rights.xpath("rif:*", ns_decl)
    nodes.each_with_object({}) do |e, memo|
      data = {}
      data[:title] = e.content
      if e.key? 'rightsUri'
        data[:href] = e['rightsUri']
        data &&= rights_data_from_url(data[:href])
      end
      memo[e.name] = data
    end
  end
  memoize(:rights)

  # Looks up licence info from the URL.
  # It looks for the canonical licence name and a logo.
  def rights_data_from_url(url)
    require 'open-uri'
    require 'locale'
    require 'uri'
    predicates = {
      RDF::DC.title => :title,
      RDF::DC11.title => :title,
      RDF::FOAF.logo => :logo
    }
    fallback_data = {:href => url}
    uri = URI.parse(url)
    begin
      doc = Nokogiri::HTML(uri.read)
      begin
        title_e = doc.at_css('html head title')
        # Get fallback data
        fallback_data[:title] = title_e.content unless title_e.nil?
      end
      # Look for RDF link
      link = doc.at_css('link[rel=alternate][type="application/rdf+xml"]')
      unless link.nil?
        uri = uri + link['href']
      end
    end
    reader = RDF::Reader.open(uri.to_s)
    data = {}
    candidate_locales = [nil] + Locale.candidates.map do |l|
      l.to_s.dasherize.downcase.to_sym
    end
    reader.each_triple do |subject, predicate, object|
      next unless predicates.keys.include?(predicate)
      if object.respond_to?(:language)
        next unless candidate_locales.include?(object.language)
      end
      data[subject.to_s] ||= {}
      data[subject.to_s][predicates[predicate]] = object.to_s
    end
    if data.keys.empty?
      # Use fallback data if possible
      fallback_data.key?(:title) ? fallback_data : nil
    else
      # Not the best way to determine the primary subject, but it should be OK
      primary_subject = data.keys.max_by(&:length)
      # Use subject URI as HREF if not otherwise set
      data[primary_subject][:href] ||= primary_subject.to_s
      data[primary_subject]
    end
  end

  def role(rifcs_doc)
    rifcs_doc = ensure_rifcs_doc(rifcs_doc)
    related_key = rifcs_doc.at_xpath(
      "//rif:relatedObject[rif:relation/@type='isCollectorOf']/rif:key")
    return "Data Collection Creator" unless related_key.nil?
    related_key = rifcs_doc.at_xpath(
      "//rif:relatedObject[rif:relation/@type='isManagerOf']/rif:key")
    return "Data Collection Manager" unless related_key.nil?
    nil
  end

  def related_objects(rifcs_doc, relationship)
    related_keys = ensure_rifcs_doc(rifcs_doc).xpath(
      "//rif:relatedObject[rif:relation/@type='#{relationship}']/rif:key")
    return [] if related_keys.nil?
    related_keys.map do |related_key|
      begin
        concept = Miletus::Merge::Concept.find_by_key!(related_key.content)
        OpenStruct.new({
          :title => concept.title,
          :type => concept.type,
          :href => concept_path(concept.uuid)
        })
      rescue
        nil
      end
    end.compact.uniq
  end

  def keywords(rifcs_doc)
    subjects(rifcs_doc).map {|s| s.name}
  end

  def subjects(rifcs_doc)
    subjects = ensure_rifcs_doc(rifcs_doc).xpath "//rif:subject"
    subjects.map do |e|
      Struct.new(:name, :type).new(e.content, e['type'].titleize.upcase)
    end
  end

  def name(rifcs_doc)
    extend Miletus::NamespaceHelper
    name = ensure_rifcs_doc(rifcs_doc).at_xpath "//rif:name[@type='primary']"
    return {} if name.nil?
    nodes = name.xpath("rif:namePart", ns_decl)
    type_content_map(nodes)
  end

  def address_urls(rifcs_doc)
    nodes = ensure_rifcs_doc(rifcs_doc).xpath(
      "//rif:location/rif:address/rif:electronic[@type='url']/rif:value")
    uniq_content(nodes)
  end

  def identifier_urls(rifcs_doc)
    nodes = ensure_rifcs_doc(rifcs_doc).xpath(
      "//rif:registryObject/rif:*/rif:identifier")
    uniq_content(nodes).select do |uri_str|
      begin
        %w[http https].include? URI.parse(uri_str).scheme
      rescue
        false
      end
    end
  end

  def type_image(type)
    type_images = {
      'activity' => 'gantt_chart.svg',
      'collection' => 'data.svg',
      'party' => 'people.svg',
      'service' => 'information_technology.svg'
    }
    if type_images.key? type
      image_tag type_images[type],
        :alt => type.titleize,
        :title => type.titleize,
        :class => 'icon'
    else
      ''
    end
  end

  private

  def ensure_rifcs_doc(rifcs_doc)
    return rifcs_doc if rifcs_doc.is_a? Miletus::Merge::RifcsDoc
    Miletus::Merge::RifcsDoc.create(rifcs_doc.to_xml)
  end

  def type_content_map(nodes)
    nodes.each_with_object({}) do |e, memo|
      t = e['type']
      memo[t] ||= []
      memo[t] << e.content
    end
  end

  # Get a hash of node children names to contents, merged with attributes
  def node_children_and_attributes(node)
    h = node.children.each_with_object({}) do |e, memo|
      memo[e.name] = e.content.strip
    end
    node.attributes.values.each_with_object(h) do |attr|
      h[attr.name] = attr.value
    end
  end

  def uniq_content(nodes)
    nodes.map(&:content).map(&:strip).uniq
  end


end
