# coding: utf-8

require 'spec_helper'

describe GoCardless::Utils do

  describe "string helpers" do
    describe ".camelize" do
      it "converts underscored words to camel case" do
        GoCardless::Utils.camelize("a_test_string").should == "ATestString"
      end
    end

    describe ".underscore" do
      it "converts camel case words to underscored form" do
        GoCardless::Utils.underscore("ATestString").should == "a_test_string"
      end
    end

    describe ".singularize" do
      it "removes trailing 's' characters" do
        GoCardless::Utils.singularize("desks").should == "desk"
      end

      it "converts 'i' suffix to 'us'" do
        GoCardless::Utils.singularize("cacti").should == "cactus"
      end
    end
  end

  describe "hash helpers" do
    describe ".symbolize_keys" do
      it "converts keys to symbols" do
        hash = {'string' => true, 123 => true, :symbol => true}
        keys = GoCardless::Utils.symbolize_keys(hash).keys
        keys.length.should == 3
        keys.should include :string
        keys.should include :'123'
        keys.should include :symbol
      end

      it "preserves the original hash" do
        hash = {'string' => true}
        GoCardless::Utils.symbolize_keys(hash)
        hash.keys.should == ['string']
      end

      it "doesn't overwrite existing symbol keys" do
        hash = {'x' => 1, :x => 2}
        GoCardless::Utils.symbolize_keys(hash).should == hash
      end

      it "works with sinatra params' default proc" do
        hash = Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
        hash['x'] = 1
        GoCardless::Utils.symbolize_keys(hash).should == {:x => 1}
      end
    end

    describe ".symbolize_keys!" do
      it "modifies the original hash" do
        hash = {'string' => true}
        GoCardless::Utils.symbolize_keys!(hash)
        hash.keys.should == [:string]
      end
    end
  end

  describe "signature helpers" do
    describe ".percent_encode" do
      subject { GoCardless::Utils.method(:percent_encode) }

      it "works with empty strings" do
        subject[""].should == ""
      end

      it "doesn't encode lowercase alpha characters" do
        subject["abcxyz"].should == "abcxyz"
      end

      it "doesn't encode uppercase alpha characters" do
        subject["ABCXYZ"].should == "ABCXYZ"
      end

      it "doesn't encode digits" do
        subject["1234567890"].should == "1234567890"
      end

      it "doesn't encode unreserved non-alphanumeric characters" do
        subject["-._~"].should == "-._~"
      end

      it "encodes non-ascii alpha characters" do
        subject["å"].should == "%C3%A5"
      end

      it "encodes reserved ascii characters" do
        subject[" !\"\#$%&'()"].should == "%20%21%22%23%24%25%26%27%28%29"
        subject["*+,/{|}:;"].should == "%2A%2B%2C%2F%7B%7C%7D%3A%3B"
        subject["<=>?@[\\]^`"].should == "%3C%3D%3E%3F%40%5B%5C%5D%5E%60"
      end

      it "encodes other non-ascii characters" do
        subject["支払い"].should == "%E6%94%AF%E6%89%95%E3%81%84"
      end
    end

    describe ".flatten_params" do
      subject { GoCardless::Utils.method(:flatten_params) }

      it "returns an empty array when provided with an empty hash" do
        subject[{}].should == []
      end

      it "converts hashes to key-value arrays" do
        subject['a' => 'b'].should == [['a', 'b']]
      end

      it "works with integer keys and values" do
        subject[123 => 456].should == [['123', '456']]
      end

      it "works with symbol keys and values" do
        subject[:a => :b].should == [['a', 'b']]
      end

      it "uses empty-bracket syntax for arrays" do
        subject['a' => ['b']].should == [['a[]', 'b']]
      end

      it "includes all array values separately" do
        subject['a' => ['b', 'c']].should == [['a[]', 'b'], ['a[]', 'c']]
      end

      it "flattens nested arrays" do
        subject['a' => [['b']]].should == [['a[][]', 'b']]
      end

      it "uses the bracket-syntax for hashes" do
        subject['a' => {'b' => 'c'}].should == [['a[b]', 'c']]
      end

      it "includes all hash k/v pairs separately" do
        hash = {'a' => {'b' => 'c', 'd' => 'e'}}
        subject[hash].should == [['a[b]', 'c'], ['a[d]', 'e']]
      end

      it "flattens nested hashes" do
        subject['a' => {'b' => {'c' => 'd'}}].should == [['a[b][c]', 'd']]
      end

      it "works with arrays inside hashes" do
        subject['a' => {'b' => ['c']}].should == [['a[b][]', 'c']]
      end

      it "works with hashes inside arrays" do
        subject['a' => [{'b' => 'c'}]].should == [['a[][b]', 'c']]
      end
    end

    describe ".normalize_params" do
      subject { GoCardless::Utils.method(:normalize_params) }

      it "percent encodes keys and values" do
        subject['!' => '+'].split('=').should == ['%21', '%2B']
      end

      it "joins items by '=' signs" do
        subject['a' => 'b'].should == 'a=b'
      end

      it "joins pairs by '&' signs" do
        subject['a' => 'b', 'c' => 'd'].should == 'a=b&c=d'
      end
    end

    describe ".sign_params" do
      it "produces the correct hash for the given params and key" do
        key = 'testsecret'
        params = {:test => true}
        sig = '6e4613b729ce15c288f70e72463739feeb05fc0b89b55d248d7f259b5367148b'
        GoCardless::Utils.sign_params(params, key).should == sig
      end
    end
  end

end
