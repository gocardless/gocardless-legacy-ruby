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

  describe "#find" do
    it "instantiates the correct object" do
      class TestResource < Grapi::Resource
        ENDPOINT = '/test/:id'
      end
      mock_client = mock
      mock_client.expects(:api_get).returns({:id => 123})
      resource = TestResource.find(mock_client, 123)
      resource.should be_a TestResource
      resource.id.should == 123
    end
  end

  describe "#reference_writer" do
    it "creates reference writers properly" do
      class TestResource < Grapi::Resource
        reference_writer :merchant_id, :user_id
      end

      TestResource.instance_methods.should include 'merchant='
      TestResource.instance_methods.should include 'merchant_id='
      TestResource.instance_methods.should include 'user='
      TestResource.instance_methods.should include 'user_id='
    end

    it "direct assignment methods work properly" do
      class TestResource < Grapi::Resource
        reference_writer :user_id
      end

      resource = TestResource.new(nil)
      resource.user = Grapi::User.from_hash(nil, :id => 123)
      resource.instance_variable_get(:@user_id).should == 123
    end

    it "requires args to end with _id" do
      expect do
        class TestResource < Grapi::Resource
          reference_writer :user
        end
      end.to raise_exception ArgumentError
    end

    it "fails with the wrong object type" do
      class TestResource < Grapi::Resource
        reference_writer :user_id
      end
      expect do
        TestResource.new(nil).user = 'asdf'
      end.to raise_exception ArgumentError
    end
  end

  describe "#reference_reader" do
    before :each do
      @app_id = 'abc'
      @app_secret = 'xyz'
      @client = Grapi::Client.new(@app_id, @app_secret)
      @redirect_uri = 'http://test.com/cb'
    end

    it "creates reference writers properly" do
      class TestResource < Grapi::Resource
        reference_reader :merchant_id, :user_id
      end

      TestResource.instance_methods.should include 'merchant'
      TestResource.instance_methods.should include 'merchant_id'
      TestResource.instance_methods.should include 'user'
      TestResource.instance_methods.should include 'user_id'
    end

    it "lookup methods work properly" do
      class TestResource < Grapi::Resource
        reference_writer :user_id
      end

      resource = TestResource.new(@client)
      resource.instance_variable_set(:@user_id, 123)
      stub_get(@client, {:id => 123})
      user = resource.user
      user.should be_a Grapi::User
      user.id.should == 123
    end

    it "requires args to end with _id" do
      expect do
        class TestResource < Grapi::Resource
          reference_reader :user
        end
      end.to raise_exception ArgumentError
    end
  end

  describe "#reference_accessor" do
    it "creates reference readers and writers" do
      class TestResource < Grapi::Resource
        reference_accessor :merchant_id, :user_id
      end

      TestResource.instance_methods.should include 'merchant'
      TestResource.instance_methods.should include 'merchant_id'
      TestResource.instance_methods.should include 'user'
      TestResource.instance_methods.should include 'user_id'
      TestResource.instance_methods.should include 'merchant='
      TestResource.instance_methods.should include 'merchant_id='
      TestResource.instance_methods.should include 'user='
      TestResource.instance_methods.should include 'user_id='
    end
  end
end

