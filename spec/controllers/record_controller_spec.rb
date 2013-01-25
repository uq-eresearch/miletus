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

    let(:today) { DateTime.now.utc.strftime('%Y-%m-%d') }

    def validate_atom
      response.should be_success
      doc = Nokogiri::XML(response.body)
      rng_schema_file = File.expand_path "atom.rng", File.dirname(__FILE__)
      schema = Nokogiri::XML::RelaxNG(File.open(rng_schema_file))
      schema.validate(doc).should be == []
    end

    describe "routes" do
      it "routes from /atom" do
        { :get => "/atom" }.should route_to(
            :controller => 'record',
            :action => 'atom')
      end

      it "routes from /atom/:date" do
        { :get => "/atom/1970-01-01" }.should route_to(
            :controller => 'record',
            :action => 'atom',
            :date => '1970-01-01')
      end

    end

    context "with no records" do
      before(:each) { get 'atom' }

      it "redirects to today's feed" do
        get 'atom'
        response.code.to_i.should be == 303
        response.should redirect_to(atom_url(:date => today))
      end

      it "returns atom" do
        get 'atom', :date => today
        validate_atom
      end
    end

    context "with a single record" do

      context "from today" do
        before(:each) do
          fixture_file = File.join(File.dirname(__FILE__),
            '..', 'fixtures',"rifcs-collection-1.xml")
          @concept = Miletus::Merge::Concept.create()
          @concept.facets.create(
            :metadata => File.open(fixture_file) { |f| f.read() }
          )
          @concept.reload
        end

        it "returns atom" do
          get 'atom', :date => today
          validate_atom
        end

        it "should have a single entry" do
          require 'atom'
          get 'atom', :date => today
          feed = Atom::Feed.load_feed(response.body)
          feed.entries.count.should be == 1
        end

        it "should not have a next-archive link" do
          require 'atom'
          get 'atom', :date => today
          feed = Atom::Feed.load_feed(response.body)
          next_archive_link = feed.links.detect{|l| l.rel == 'next-archive'}
          next_archive_link.should be_nil
        end
      end

      context "from two days ago" do
        before(:each) do
          fixture_file = File.join(File.dirname(__FILE__),
            '..', 'fixtures',"rifcs-collection-1.xml")
          @concept = Miletus::Merge::Concept.create()
          @concept.facets.create(
            :metadata => File.open(fixture_file) { |f| f.read() }
          )
          @concept.reload
          @concept.class.record_timestamps = false
          @concept.updated_at = (Date.today - 2).to_datetime
          @concept.save
          @concept.class.record_timestamps = true
        end

        it "returns atom" do
          get 'atom', :date => today
          validate_atom
        end

        it "should have a no entries" do
          require 'atom'
          get 'atom', :date => today
          feed = Atom::Feed.load_feed(response.body)
          feed.entries.count.should be == 0
        end

        it "should have prev-archive link for two days ago" do
          require 'atom'
          get 'atom', :date => today
          feed = Atom::Feed.load_feed(response.body)
          prev_archive_link = feed.links.detect{|l| l.rel == 'prev-archive'}
          prev_archive_link.should_not be_nil
          prev_archive_link.href.should be == \
            atom_url(@concept.updated_at.to_date.iso8601)
        end

        context "the archive feed for two days ago" do

          before(:each) do
            get 'atom', :date => @concept.updated_at.to_date.iso8601
          end

          it "should have next-archive link for today" do
            require 'atom'
            feed = Atom::Feed.load_feed(response.body)
            next_archive_link = feed.links.detect{|l| l.rel == 'next-archive'}
            next_archive_link.should_not be_nil
            next_archive_link.href.should be == atom_url(today)
          end

          it "should have a public cache age of 30 days" do
            response.headers['Cache-Control'].should be == \
              "max-age=2592000, public"
          end

        end


      end

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
