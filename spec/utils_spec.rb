require 'spec_helper'

describe String do
  describe "#camelize" do
    it "converts underscored words to camel case" do
      "a_test_string".camelize.should == "ATestString"
    end
  end

  describe "#underscore" do
    it "converts camel case words to underscored form" do
      "ATestString".underscore.should == "a_test_string"
    end
  end

  describe "#singularize" do
    it "removes trailing 's' characters" do
      "desks".singularize.should == "desk"
    end

    it "converts 'i' suffix to 'us'" do
      "cacti".singularize.should == "cactus"
    end
  end
end

describe Hash do
  describe "#symbolize_keys" do
    it "converts keys to symbols" do
      hash = {'string' => true, 123 => true, :symbol => true}
      keys = hash.symbolize_keys.keys
      keys.length.should == 3
      keys.should include :string
      keys.should include :'123'
      keys.should include :symbol
    end

    it "preserves the original hash" do
      hash = {'string' => true}
      hash.symbolize_keys
      hash.keys.should == ['string']
    end
  end

  describe "#symbolize_keys!" do
    it "modifies the original hash" do
      hash = {'string' => true}
      hash.symbolize_keys!
      hash.keys.should == [:string]
    end
  end
end
