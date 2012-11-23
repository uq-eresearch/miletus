require 'spec_helper'

describe RifcsRecordObserver do

  subject { RifcsRecordObserver.instance }

  it { should respond_to(
        :after_create, :after_update, :after_destroy, :after_touch) }

  describe "RIF-CS splitting with Reader" do

    def split_rifcs_document(record)
      xml = record.to_rif
      return [] if xml.nil?
      combined_doc = Nokogiri::XML(xml)
      combined_doc.root.children.select do |node|
        node.element?
      end.map do |element|
        separate_doc = combined_doc.clone
        separate_doc.root.children = element.clone
        separate_doc.to_xml
      end
    end

    class DummyJob < RifcsRecordObserver::AbstractJob; end

    it "should split identically to a DOM-based parser" do
      record = nil
      VCR.use_cassette('ands_rifcs_example') do
        require 'open-uri'
        url = 'http://services.ands.org.au/documentation/rifcs/example/rif.xml'
        xml = open(url).read
        record = Struct.new(:to_rif).new(xml)
      end
      job = DummyJob.new(record)
      # Check the number is at least correct
      job.split_rifcs_document.count.should be == 4
      # Check that each doc is the same
      expected_docs = split_rifcs_document(record)
      actual_docs = job.split_rifcs_document
      expected_docs.zip(actual_docs).each do |expected, actual|
        actual.should == expected
      end
    end

    it "should use :to_rif_file if available" do
      record, f_rec = nil
      VCR.use_cassette('ands_rifcs_example') do
        require 'open-uri'
        url = 'http://services.ands.org.au/documentation/rifcs/example/rif.xml'
        xml = open(url).read
        record = Struct.new(:to_rif).new(xml)
        f_rec = Object.new
        f_rec.should_receive(:to_rif_file).once.and_return(StringIO.new(xml))
      end
      job = DummyJob.new(f_rec)
      # Check that each doc is the same
      expected_docs = split_rifcs_document(record)
      actual_docs = job.split_rifcs_document
      expected_docs.zip(actual_docs).each do |expected, actual|
        actual.should == expected
      end
    end

  end

  describe "OAIPMH RIF-CS observation" do

    def create_input_record(type = 'party', fixture_id = 1)
      # Load data from fixture
      fixture_file = File.join(File.dirname(__FILE__),
        '..', 'fixtures',"rifcs-#{type}-#{fixture_id}.xml")
      xml = File.open(fixture_file) { |f| f.read }
      # Create collection
      rc = Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.create(
        :endpoint => 'http://example.test/oai'
      )
      # Create record
      Miletus::Harvest::OAIPMH::RIFCS::Record.new.tap do |r|
        r.record_collection = rc
        r.identifier = 'http://example.test/1'
        r.datestamp = Time.now
        r.metadata = Nokogiri::XML(xml).tap do |doc|
          old_root = doc.root
          doc.root = Nokogiri::XML::Node.new('metadata', doc)
          doc.root << old_root
        end.to_s
        r.save!
      end
    end

    it "should create a new concept for a new harvested record" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      input_record = create_input_record
      # Run hook - which will happen as part of the environment
      # subject.after_create(input_record)
      # A new concept should exist as a result
      concept = Miletus::Merge::Concept.find(:first)
      concept.should_not be(nil)
      concept.to_rif.should_not be(nil)
      doc = Nokogiri::XML(concept.to_rif)
      doc.at_xpath('/rif:registryObjects', ns_decl).should_not be_nil
    end

    it "should update concept when the harvested record changes" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      input_record = create_input_record
      # Run hook - which will happen as part of the environment
      # subject.after_create(input_record)
      Miletus::Merge::Concept.all.count.should be == 1
      # A new concept should exist as a result
      concept = Miletus::Merge::Concept.find(:first)
      concept.should_not be_nil
      concept.to_rif.should_not be_nil
      # Change input record
      input_record.reload
      doc = Nokogiri::XML(input_record.metadata)
      nodes = doc.xpath("//rif:namePart[@type='given'][text()='John']",
        'rif' => 'http://ands.org.au/standards/rif-cs/registryObjects')
      nodes.each do |e|
        e.remove
      end
      input_record.metadata = doc
      input_record.save!
      # Run hook - which will happen as part of the environment
      # subject.after_update(input_record)
      # Check the concept was updated
      Miletus::Merge::Concept.all.count.should be == 1
      concept = Miletus::Merge::Concept.find(:first)
      rifcs_doc = Nokogiri::XML::Document.parse(concept.to_rif)
      rifcs_doc.xpath("//rif:namePart[@type='given'][text()='John']",
        'rif' => 'http://ands.org.au/standards/rif-cs/registryObjects')\
         .should be_empty
    end

    it "should delete facets when the harvested record is marked deleted" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      input_record = create_input_record
      # Run hook - which will happen as part of the environment
      # subject.after_create(input_record)
      Miletus::Merge::Concept.all.count.should be == 1
      # A new record should exist as a result
      concept = Miletus::Merge::Concept.find(:first)
      concept.should_not be_nil
      concept.to_rif.should_not be_nil
      # Delete input record
      input_record.reload
      input_record.deleted = true
      input_record.save!
      # Run hook - which will happen as part of the environment
      # subject.after_update(input_record)
      # Check the concept was removed
      Miletus::Merge::Concept.all.should be_empty
    end


    it "should delete facets when the harvested record is destroyed" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      input_record = create_input_record
      # Run hook - which will happen as part of the environment
      # subject.after_create(input_record)
      Miletus::Merge::Concept.all.count.should be == 1
      # A new record should exist as a result
      concept = Miletus::Merge::Concept.find(:first)
      concept.should_not be_nil
      concept.to_rif.should_not be_nil
      # Destroy input record
      input_record.destroy
      # Run hook - which will happen as part of the environment
      # subject.after_destroy(input_record)
      # Check the concept was removed
      Miletus::Merge::Concept.all.should be_empty
    end

    it "should merge output record data when identifiers match" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      input_record_1 = create_input_record('party', 1)
      # Run hook - which will happen as part of the environment
      # subject.after_create(input_record)
      Miletus::Merge::Concept.all.count.should be == 1
      # Run hook - which will happen as part of the environment
      input_record_2 = create_input_record('party', '1b')
      Miletus::Merge::Concept.all.count.should be == 1
      # A new record should exist as a result
      concept = Miletus::Merge::Concept.find(:first)
      concept.should_not be(nil)
      concept.to_rif.should_not be(nil)
      concept.should have(2).facets
    end

    it "should update on touch" do
      # Disable delayed run for hooks, and expect two job runs
      RifcsRecordObserver.should_receive(:run_job).twice \
        .and_return { |j| j.run }
      # Create record (run #1)
      input_record = create_input_record('party', 1)
      # Trigger update (run #2)
      input_record.touch
    end

  end

  describe "RIF-CS Document Observation" do

    let :fixture_url do
      fixture_file = File.expand_path(
        File.join(File.dirname(__FILE__),
          '..', 'fixtures', 'rifcs-activity-1.xml'))
      'file://%s' % fixture_file
    end

    it "should create a new concept for a single object document" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      # Check the database has no existing concepts
      Miletus::Merge::Concept.count.should be == 0
      # Create entry
      document = Miletus::Harvest::Document::RIFCS.new(:url => fixture_url)
      document.save!
      document.fetch
      # Check that associated concepts have been created
      Miletus::Merge::Concept.count.should == 1
    end

    it "should create a new concepts for a multiple object document" do
      # Disable delayed run for hooks
      RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
      # Check the database has no existing concepts
      Miletus::Merge::Concept.count.should be == 0
      # Create entry
      VCR.use_cassette('ands_rifcs_example') do
        document = Miletus::Harvest::Document::RIFCS.new(
          :url => \
            'http://services.ands.org.au/documentation/rifcs/example/rif.xml')
        document.save!
        document.fetch
      end
      # Check that associated concepts have been created
      Miletus::Merge::Concept.count.should == 4
    end

  end


end
