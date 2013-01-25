require 'spec_helper'

describe Miletus::Output::Atom do

  it { respond_to(:feed) }

  describe ".feed" do

    it "should produce an Atom::Feed for a date" do
      subject.feed(Date.today, {:host => 'example.test'}).should \
        be_a_kind_of(Atom::Feed)
    end



  end

end