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

    def cassette_name(value)
      'nla_lookup_for_%s' % value.gsub('/','_')
    end

    it "does not work with values ending in a backslash character" do
      value = 'foobar\\'
      VCR.use_cassette(cassette_name(value)) do
        lambda {
          TroveSRU.lookup_nla_id(nil, value, USE_TEST)
        }.should raise_error(TroveSRU::DataError)
      end
    end

    it "successfully returns NLA Party Identifier (any type)" do
      value = TARGET_VALUE
      VCR.use_cassette(cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(nil, value, USE_TEST)
        nla.should == EXPECTED_NLA_ID
      end
    end

    it "successfully returns NLA Party Identifier (explicit type)" do
      value = TARGET_VALUE
      VCR.use_cassette(cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(TARGET_TYPE, value, USE_TEST)
        nla.should == EXPECTED_NLA_ID
      end
    end

    it "works with the other SRU service too" do
      value = TARGET_VALUE
      VCR.use_cassette("%s_with_other" % cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(TARGET_TYPE, value, ! USE_TEST)
        nla.should == EXPECTED_NLA_ID
      end
    end

    it "fails when no value match (any type)" do
      value = WRONG_VALUE
      VCR.use_cassette(cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(nil, value, USE_TEST)
        nla.should == nil
      end
    end

    it "fails when no value match (explicit type)" do
      value = WRONG_VALUE
      VCR.use_cassette(cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(TARGET_TYPE, value, USE_TEST)
        nla.should == nil
      end
    end

    it "fails when value matches, but explicit type does not" do
      value = WRONG_VALUE
      VCR.use_cassette(cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(WRONG_TYPE, value, USE_TEST)
        nla.should == nil
      end
    end

    it "fails for false-positive value matches (any type)" do
      value = TARGET_VALUE.chop
      VCR.use_cassette(cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(nil, value, USE_TEST)
        nla.should == nil
      end
    end

    it "fails for false-positive value matches (explicit type)" do
      value = TARGET_VALUE.chop
      VCR.use_cassette(cassette_name(value)) do
        nla = TroveSRU.lookup_nla_id(TARGET_TYPE, value, USE_TEST)
        nla.should == nil
      end
    end

    it "throws an error if multiple values are returned" do
      value = 'dataspace.uq.edu.au'
      VCR.use_cassette(cassette_name(value)) do
        lambda {
          TroveSRU.lookup_nla_id(nil, value, USE_TEST)
        }.should raise_error(TroveSRU::DataError)
      end
    end

  end

end

#EOF
