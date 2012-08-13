require 'spec_helper'

describe Miletus::Harvest::OAIPMH::RIFCS do

  it "should expose jobs for updating record collections" do
    Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.create(
      :endpoint => 'http://example.test/oai')
    subject.should have(1).jobs
    subject.jobs.first.tap do |job|
      job.should respond_to(:update)
      job.should respond_to(:perform)
      job.should_receive(:update)
      job.perform
    end
  end

end
