require 'spec_helper'

describe AdminUser do

  it "is by default populated with one admin" do
    subject.class.count.should == 1
  end

end
