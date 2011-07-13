require 'spec_helper'

describe Grapi::Merchant do
  it "initializes from hash" do
    props = {:id => 1, :name => 'test', :uri => 'http://test'}
    merchant = Grapi::Merchant.from_hash(props)
    props.each { |k,v| merchant.send(k).should == v }
  end

  it "converts created_at to date" do
    merchant = Grapi::Merchant.new
    merchant.created_at = '2011-12-12T12:00:00Z'
    merchant.created_at.should be_instance_of DateTime
  end
end

