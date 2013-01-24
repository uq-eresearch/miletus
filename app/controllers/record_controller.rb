require 'miletus'

class RecordController < ApplicationController

  def index
    concepts = Miletus::Merge::Concept.order(:sort_key).all
    @concepts, @types = [], Set.new
    concepts.each do |c|
      next if c.type.nil?
      @types << c.type
      @concepts << c
    end
  end

  def view
    k = [:id, :uuid].detect {|sym| params.key?(sym) }
    @concept = Miletus::Merge::Concept.send('find_by_%s!' % k, params[k])
    # Redirect if a better path exists
    if k == :id and @concept.uuid
      redirect_to :action => 'view', :uuid => @concept.uuid, :status => 301
    end
    @doc = Miletus::Merge::RifcsDoc.create(@concept.to_rif)
  end

  def view_format
    case params[:format]
    when 'html'
      redirect_to :action => 'view', :uuid => params[:uuid], :status => 301
    when 'rifcs.xml'
      concept = Miletus::Merge::Concept.find_by_uuid(params[:uuid]) || not_found
      if stale?(:last_modified => concept.updated_at, :public => true)
        xml = concept.to_rif || not_found
        render :text => xml, :content_type => 'text/xml'
      end
    else
      not_found
    end
  end

  def graph
    # No data required
  end

  def atom
    render :text => atom_feed.to_xml, :content_type => 'application/atom+xml'
  end

  def gexf
    target = params.key?(:id) ?
      Miletus::Merge::Concept.find_by_id!(params[:id]) : Miletus::Merge::Concept
    if stale?(:last_modified => target.updated_at, :public => true)
      render :text => target.to_gexf, :content_type => 'text/xml'
    end
  end

  def sitemap
    extend Miletus::NamespaceHelper
    if Miletus::Merge::Concept.count > 0
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.urlset(:xmlns => ns_by_prefix('sitemap').uri) {
          Miletus::Merge::Concept.all.each do |concept|
            xml.url {
              url = URI::HTTP.build(
                :scheme => request.scheme,
                :host => request.host,
                :port => request.port,
                :path => concept_path(:uuid => concept.uuid)
              )
              xml.loc url
              xml.lastmod concept.updated_at.iso8601
            }
          end
        }
      end
      render :content_type => 'text/xml', :text => builder.to_xml
    else
      render :status => 404, :text => ''
    end
  end

  private

  def atom_feed
    require 'atom'
    Atom::Feed.new do |feed|
      # Order is important
      feed.id = atom_feed_url
      feed.updated = Miletus::Merge::Concept.updated_at || DateTime.now
      feed.title = 'Miletus Atom Feed'
      feed.generator = Atom::Generator.new(
        :name => 'Miletus',
        :uri => 'https://github.com/uq-eresearch/miletus')
      # Mark feed as complete (disabled for now, due to ratom bug)
      # feed['http://purl.org/syndication/history/1.0', 'complete'] << ''
      # Add entries
      Miletus::Merge::Concept.order('updated_at DESC').all.each do |concept|
        feed.entries << Atom::Entry.new do |entry|
          entry.id = concept_id_url(:id => concept.id)
          entry.updated = concept.updated_at
          entry.title = concept.title
          if concept.uuid
            entry.links << Atom::Link.new({
              :rel => 'alternate',
              :type => 'application/rifcs+xml',
              :href => concept_format_url({
                :uuid => concept.uuid,
                :format => 'rifcs.xml'
              })
            })
          end
        end
      end
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

end
