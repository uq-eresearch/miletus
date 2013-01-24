require 'spec_helper'

describe RecordController do

  def get_fixture(type, number = 1)
    fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{number}.xml")
    File.open(fixture_file) { |f| f.read() }
  end


  subject { RecordController.new }

  describe "routing" do

    it "should provide /browse with #index" do
      {
        :get => "/browse"
      }.should route_to(:controller => 'record', :action => 'index')
    end

  end

  describe "GET 'index'" do
    subject do
      get 'index'
      response
    end

    context "when no concepts exist" do
      it { should be_success }
    end

    context "when concepts exist" do
      before(:each) do
        Miletus::Merge::Concept.create()
        Miletus::Merge::Concept.create().tap do |concept|
          concept.type = 'activity'
          concept.save!
        end
      end
      it { should be_success }
    end
  end

  describe "GET 'view'" do

    before(:each) do
      fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-collection-1.xml")
      @concept = Miletus::Merge::Concept.create()
      @concept.facets.create(
        :metadata => File.open(fixture_file) { |f| f.read() }
      )
      @concept.reload
    end

    it "returns http success for uuid fetch" do
      get 'view', :uuid => @concept.uuid
      response.should be_success
    end

    it "returns http redirect for id fetch" do
      get 'view', :id => @concept.id
      response.should be_redirect
    end

    it "returns http success for id fetch when no uuid exists" do
      concept = Miletus::Merge::Concept.create()
      get 'view', :id => concept.id
      response.should be_success
    end

  end

  describe "GET 'view_format'" do

    before(:each) do
      fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-collection-1.xml")
      @concept = Miletus::Merge::Concept.create()
      @concept.facets.create(
        :metadata => File.open(fixture_file) { |f| f.read() }
      )
      @concept.reload
    end

    context "HTML" do
      it "routes to :view_format when an extension is specified" do
        { :get => "/records/#{@concept.uuid}.html" }.should route_to(
          :controller => 'record',
          :action => 'view_format',
          :uuid => @concept.uuid,
          :format => 'html')
      end

      it "returns http redirect" do
        get 'view_format', :uuid => @concept.uuid, :format => 'html'
        response.should be_redirect
      end
    end

    context "RIF-CS" do
      render_views

      it "returns valid RIF-CS XML" do
        include Miletus::NamespaceHelper
        get 'view_format', :uuid => @concept.uuid, :format => 'rifcs.xml'
        response.should be_success
        doc = Nokogiri::XML(response.body)
        ns_by_prefix('rif').schema.validate(doc).should be == []
      end

      it "returns 404 if RIF-CS XML is unavailable" do
        # Bad XML (UUID will be found)
        @concept.facets.first.tap {|f| f.metadata = '<xml/>'; f.save!}
        @concept.reload
        lambda do
          get 'view_format', :uuid => @concept.uuid, :format => 'rifcs.xml'
        end.should raise_error(ActionController::RoutingError)
        # No facets
        @concept.facets.destroy_all
        lambda do
          get 'view_format', :uuid => @concept.uuid, :format => 'rifcs.xml'
        end.should raise_error(ActionController::RoutingError)
      end

      it "sends 304 Not Modified based on update time" do
        @request.env['HTTP_IF_MODIFIED_SINCE'] = @concept.updated_at.httpdate
        get 'view_format', :uuid => @concept.uuid, :format => 'rifcs.xml'
        response.status.should be == 304
      end

    end

    context "unknown format" do
      it "returns 404 Not Found" do
        include Miletus::NamespaceHelper
        lambda do
          get 'view_format', :uuid => @concept.uuid, :format => 'unknown'
        end.should raise_error(ActionController::RoutingError)
      end
    end

  end

  describe "GET 'atom'" do

    def validate_atom
      response.should be_success
      doc = Nokogiri::XML(response.body)
      rng_schema_file = File.expand_path "atom.rng", File.dirname(__FILE__)
      schema = Nokogiri::XML::RelaxNG(File.open(rng_schema_file))
      schema.validate(doc).should be == []
    end

    it "has a route from /records.atom" do
      { :get => "/records.atom" }.should route_to(
          :controller => 'record',
          :action => 'atom')
    end

    context "with no records" do
      before(:each) { get 'atom' }

      it "returns atom" do
        get 'atom'
        validate_atom
      end
    end

    context "with a single record" do
      before(:each) do
        fixture_file = File.join(File.dirname(__FILE__),
          '..', 'fixtures',"rifcs-collection-1.xml")
        @concept = Miletus::Merge::Concept.create()
        @concept.facets.create(
          :metadata => File.open(fixture_file) { |f| f.read() }
        )
        @concept.reload
      end

      before(:each) { get 'atom' }

      it "returns atom" do
        puts response.body
        validate_atom
      end

      it "should have a single entry" do
        require 'atom'
        feed = Atom::Feed.load_feed(response.body)
        feed.entries.count.should be == 1
      end

      #it "should be complete" do
      #  require 'atom'
      #  feed = Atom::Feed.load_feed(response.body)
      #  feed.extend(Miletus::Harvest::Atom::FeedMixin)
      #  feed.should be_complete
      #end

    end

  end

  describe "GET 'gexf'" do
    it "returns valid GEXF graph" do
      get 'gexf'
      response.should be_success
      doc = Nokogiri::XML(response.body)
      ns_by_prefix('gexf').schema.validate(doc).should be == []
    end
  end

  describe "GET 'sitemap'" do

    it "should return a not found if no records exist XML sitemap" do
      get 'sitemap'
      response.should be_not_found
    end

    it "returns a valid XML sitemap for all existing records" do
      concept = Miletus::Merge::Concept.create()
      [1, '1d'].map{|n| get_fixture('party', n)}.each do |fixture_xml|
        concept.facets.create(:metadata => fixture_xml)
      end

      get 'sitemap'
      response.should be_success
      doc = Nokogiri::XML(response.body)
      ns_by_prefix('sitemap').schema.validate(doc).should be == []
    end

  end

end
