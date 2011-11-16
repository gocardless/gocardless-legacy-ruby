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

end
