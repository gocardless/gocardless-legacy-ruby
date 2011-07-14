require 'spec_helper'

describe Grapi::Resource do
  it "initializes from hash" do
    class TestResource < Grapi::Resource
      attr_accessor :id, :name, :uri
    end
    props = {:id => 1, :name => 'test', :uri => 'http://test'}
    resource = TestResource.from_hash(mock, props)
    props.each { |k,v| resource.send(k).should == v }
  end

  describe "#date_writer" do
    it "creates date writers properly" do
      class TestResource < Grapi::Resource
        date_writer :created_at, :modified_at
      end

      TestResource.instance_methods.should include 'created_at='
      TestResource.instance_methods.should include 'modified_at='
    end

    it "date writers work properly" do
      class TestResource < Grapi::Resource
        date_writer :created_at
      end

      resource = TestResource.new(nil)
      time = '2011-12-12T12:00:00Z'
      resource.created_at = time
      date_time = resource.instance_variable_get(:@created_at)
      date_time.should be_instance_of DateTime
      date_time.strftime('%Y-%m-%dT%H:%M:%SZ').should == time
    end
  end

  describe "#date_accessor" do
    it "creates date readers and writers properly" do
      class TestResource < Grapi::Resource
        date_accessor :created_at, :modified_at
      end

      TestResource.instance_methods.should include 'created_at='
      TestResource.instance_methods.should include 'created_at'
      TestResource.instance_methods.should include 'modified_at='
      TestResource.instance_methods.should include 'modified_at'
    end

    it "date readers work properly" do
      class TestResource < Grapi::Resource
        date_accessor :created_at
      end

      resource = TestResource.new(nil)
      date = DateTime.now
      resource.instance_variable_set(:@created_at, date)
      resource.created_at.should == date
    end
  end
end

