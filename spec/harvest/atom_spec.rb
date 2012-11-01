require 'spec_helper'

describe Miletus::Harvest::Atom do

  it "should expose jobs for updating feeds" do
    Miletus::Harvest::Atom::Feed.create(
      :url => 'http://example.test/feed.atom')
    subject.should have(1).jobs
    subject.jobs.each do |job|
      job.should respond_to(:perform)
    end
  end

end
