#!/usr/bin/env ruby
#
# RSpec tests for TroveSRU.
#
# Copyright (C) 2012, The University of Queensland.
#----------------------------------------------------------------

require 'spec_helper'
require 'miletus/trove_sru.rb'

describe TroveSRU do

  USE_TEST = true # true = use Trove Test SRU; false = use production Trove SRU

  TARGET_TYPE = 'AU-QU'
  TARGET_VALUE = 'mirage.cmm.uq.edu.au/user/1'
  EXPECTED_NLA_ID = 'http://nla.gov.au/nla.party-1486629'
  WRONG_TYPE = 'foobar'
  WRONG_VALUE = 'foobar'

  describe "#self.lookup_nla_id" do

    it "does not work with values ending in a backslash character" do
      lambda {
        TroveSRU.lookup_nla_id(nil, 'foobar\\', USE_TEST)
      }.should raise_error(TroveSRU::DataError)
    end

    it "successfully returns NLA Party Identifier (any type)" do
      nla = TroveSRU.lookup_nla_id(nil, TARGET_VALUE, USE_TEST)
      nla.should == EXPECTED_NLA_ID
    end

    it "successfully returns NLA Party Identifier (explicit type)" do
      nla = TroveSRU.lookup_nla_id(TARGET_TYPE, TARGET_VALUE, USE_TEST)
      nla.should == EXPECTED_NLA_ID
    end

    it "works with the other SRU service too" do
      nla = TroveSRU.lookup_nla_id(TARGET_TYPE, TARGET_VALUE, ! USE_TEST)
      nla.should == EXPECTED_NLA_ID
    end

    it "fails when no value match (any type)" do
      nla = TroveSRU.lookup_nla_id(nil, WRONG_VALUE, USE_TEST)
      nla.should == nil
    end

    it "fails when no value match (explicit type)" do
      nla = TroveSRU.lookup_nla_id(TARGET_TYPE, WRONG_VALUE, USE_TEST)
      nla.should == nil
    end

    it "fails when value matches, but explicit type does not" do
      nla = TroveSRU.lookup_nla_id(WRONG_TYPE, TARGET_VALUE, USE_TEST)
      nla.should == nil
    end

    it "fails for false-positive value matches (any type)" do
      nla = TroveSRU.lookup_nla_id(nil, TARGET_VALUE.chop, USE_TEST)
      nla.should == nil
    end

    it "fails for false-positive value matches (explicit type)" do
      nla = TroveSRU.lookup_nla_id(TARGET_TYPE, TARGET_VALUE.chop, USE_TEST)
      nla.should == nil
    end

  end

end

#EOF
