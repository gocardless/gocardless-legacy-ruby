require 'spec_helper'

describe Grapi::Resource do
  it "initializes from hash" do
    class Grapi::Resource
      attr_accessor :id, :name, :uri
    end
    props = {:id => 1, :name => 'test', :uri => 'http://test'}
    resource = Grapi::Resource.from_hash(nil, props)
    props.each { |k,v| resource.send(k).should == v }
  end
end

