require 'spec_helper'
require 'yaml'

describe Miletus::Harvest::Document::RIFCS do

  it { should respond_to(:url, :document, :fetch, :to_rif) }

  it "should work for the file scheme" do
    subject.url = 'file://%s' % File.expand_path(
      File.join(File.dirname(__FILE__),
        '..', '..', 'fixtures', 'rifcs-activity-1.xml'))
    subject.save!
    subject.fetch
    subject.document.should be_file
  end

end