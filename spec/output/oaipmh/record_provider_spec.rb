require 'spec_helper'

describe Miletus::Output::OAIPMH::RecordProvider do

  it "should have a RIF-CS format registered" do
    subject.class.format_supported?('rif').should be(true)
  end

end