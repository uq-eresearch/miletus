require 'spec_helper'
require 'yaml'

describe Miletus::Harvest::Document::RIFCS do

  it { should respond_to(:url, :document, :fetch, :to_rif) }

  it "should work for the file scheme" do
    fixture_file = File.expand_path(
      File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures', 'rifcs-activity-1.xml'))
    subject.url = 'file://%s' % fixture_file
    subject.save!
    subject.fetch
    subject.document.should be_present
    subject.to_rif.should == File.read(fixture_file)
    subject.document.content_type.should == 'application/xml'
  end

end