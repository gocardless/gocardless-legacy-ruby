require 'spec_helper'

describe GoCardless::Resource do
  it "initializes from hash" do
    test_resource = Class.new(GoCardless::Resource) do
      attr_accessor :id, :name, :uri
    end
    props = {:id => 1, :name => 'test', :uri => 'http://test'}
    resource = test_resource.new(props)
    props.each { |k,v| resource.send(k).should == v }
  end

  describe "#date_writer" do
    let(:test_resource) do
      Class.new(GoCardless::Resource) { date_writer :created_at, :modified_at }
    end

    describe "creates date writers" do
      specify { test_resource.instance_methods.map(&:to_sym).should include :created_at= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :modified_at= }
    end

    it "date writers work properly" do
      time = '2011-12-12T12:00:00Z'
      resource = test_resource.new(:created_at => time)
      date_time = resource.instance_variable_get(:@created_at)
      date_time.should be_instance_of DateTime
      date_time.strftime('%Y-%m-%dT%H:%M:%SZ').should == time
    end
  end

  describe "#date_accessor" do
    let(:test_resource) do
      Class.new(GoCardless::Resource) { date_accessor :created_at, :modified_at }
    end

    describe "creates date readers and writers" do
      specify { test_resource.instance_methods.map(&:to_sym).should include :created_at= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :created_at }
      specify { test_resource.instance_methods.map(&:to_sym).should include :modified_at= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :modified_at }
    end

    it "date readers work properly" do
      resource = test_resource.new
      date = DateTime.now
      resource.instance_variable_set(:@created_at, date)
      resource.created_at.should == date
    end
  end

  describe ".find_with_client" do
    let(:test_resource) do
      Class.new(GoCardless::Resource) { self.endpoint = '/test/:id' }
    end

    it "instantiates the correct object" do
      mock_client = double
      mock_client.should_receive(:api_get).and_return({:id => 123})
      resource = test_resource.find_with_client(mock_client, 123)
      resource.should be_a test_resource
      resource.id.should == 123
    end
  end

  describe ".find" do
    let(:test_resource) do
      Class.new(GoCardless::Resource) { self.endpoint = '/test/:id' }
    end

    it "calls find with the default client" do
      GoCardless.stub(:client => double)
      test_resource.should_receive(:find_with_client).with(GoCardless.client, 1)
      test_resource.find(1)
      unset_ivar GoCardless, :client
    end

    it "raises a helpful error when there is no default client" do
      expect { test_resource.find(1) }.to raise_error
    end
  end

  describe "#reference_writer" do
    let(:test_resource) do
      Class.new(GoCardless::Resource) { reference_writer :merchant_id, :user_id }
    end

    describe "creates reference writers" do
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant_id= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user_id= }
    end

    it "direct assignment methods work properly" do
      resource = test_resource.new
      resource.user = GoCardless::User.new(:id => 123)
      resource.instance_variable_get(:@user_id).should == 123
    end

    it "requires args to end with _id" do
      expect do
        test_resource = Class.new(GoCardless::Resource) do
          reference_writer :user
        end
      end.to raise_exception ArgumentError
    end

    it "fails with the wrong object type" do
      expect { test_resource.new.user = 'asdf' }.to raise_exception ArgumentError
    end
  end

  describe "#reference_reader" do
    before :each do
      @app_id = 'abc'
      @app_secret = 'xyz'
      @client = GoCardless::Client.new(:app_id => @app_id, :app_secret => @app_secret)
      @redirect_uri = 'http://test.com/cb'
    end

    let(:test_resource) do
      Class.new(GoCardless::Resource) { reference_reader :merchant_id, :user_id }
    end

    describe "creates reference readers" do
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant }
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant_id }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user_id }
    end

    it "lookup methods work properly" do
      resource = test_resource.new_with_client(@client)
      resource.instance_variable_set(:@user_id, 123)
      @client.access_token = 'TOKEN'
      @client.merchant_id = '123'
      stub_get(@client, {:id => 123})
      user = resource.user
      user.should be_a GoCardless::User
      user.id.should == 123
    end

    it "requires args to end with _id" do
      expect do
        test_resource = Class.new(GoCardless::Resource) do
          reference_reader :user
        end
      end.to raise_exception ArgumentError
    end
  end

  describe "#reference_accessor" do
    let(:test_resource) do
      Class.new(GoCardless::Resource) do
        reference_accessor :merchant_id, :user_id
      end
    end

    describe "creates reference readers and writers" do
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant }
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant_id }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user_id }
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :merchant_id= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user= }
      specify { test_resource.instance_methods.map(&:to_sym).should include :user_id= }
    end
  end

  it "#persisted? works" do
    GoCardless::Resource.new.persisted?.should be_false
    GoCardless::Resource.new(:id => 1).persisted?.should be_true
  end

  describe "#save" do
    describe "succeeds and" do
      before :each do
        @test_resource = Class.new(GoCardless::Resource) do
          self.endpoint = '/test'
          attr_accessor :x, :y
          creatable
          updatable
        end
      end

      after :each do
        @test_resource = nil
      end

      it "sends the correct data parameters" do
        client = double
        data = {:x => 1, :y => 2}
        resource = @test_resource.new_with_client(client, data)
        client.should_receive(:api_post).with(anything, data)
        resource.save
      end

      it "sends the correct path" do
        client = double
        resource = @test_resource.new_with_client(client)
        client.should_receive(:api_post).with('/test', anything)
        resource.save
      end

      it "POSTs when not persisted" do
        client = double
        resource = @test_resource.new_with_client(client)
        client.should_receive(:api_post)
        resource.save
      end

      it "PUTs when already persisted" do
        client = double
        resource = @test_resource.new_with_client(client, :id => 1)
        client.should_receive(:api_put)
        resource.save
      end
    end

    it "succeeds when not persisted and create allowed" do
      test_resource = Class.new(GoCardless::Resource) do
        self.endpoint = '/test'
        creatable
      end

      client = double('client', :api_post => nil)
      test_resource.new_with_client(client).save
    end

    it "succeeds when persisted and update allowed" do
      test_resource = Class.new(GoCardless::Resource) do
        self.endpoint = '/test'
        updatable
      end

      client = double('client', :api_put => nil)
      test_resource.new_with_client(client, :id => 1).save
    end

    it "fails when not persisted and create not allowed" do
      test_resource = Class.new(GoCardless::Resource) do
        updatable
      end

      expect { test_resource.new.save }.to raise_error
    end

    it "fails when persisted and update not allowed" do
      test_resource = Class.new(GoCardless::Resource) do
        creatable
      end

      expect { test_resource.new(:id => 1).save }.to raise_error
    end
  end

  it "#to_hash pulls out the correct attributes" do
    test_resource = Class.new(GoCardless::Resource) do
      attr_accessor :x
    end

    attrs = {:id => 1, :uri => 'http:', :x => 'y'}
    resource = test_resource.new_with_client(double, attrs)
    resource.to_hash.should == attrs
  end

  it "#to_json converts to the correct JSON format" do
    test_resource = Class.new(GoCardless::Resource) do
      attr_accessor :amount
      date_accessor :when
      reference_accessor :person_id
    end

    time_str = '2012-01-01T00:00:00Z'
    bill = test_resource.new({
      :amount => '10',
      :when => Time.parse(time_str),
      :person_id => 15
    })

    result = MultiJson.decode(bill.to_json)
    result['amount'].should == bill.amount
    result['when'].should == time_str
    result['person_id'].should == 15
  end

  describe "resource permissions" do
    it "are not given by default" do
      GoCardless::Resource.creatable?.should be_false
      GoCardless::Resource.updatable?.should be_false
    end

    it "are present when specified" do
      class CreatableResource < GoCardless::Resource
        creatable
      end

      class UpdatableResource < GoCardless::Resource
        updatable
      end

      CreatableResource.creatable?.should be_true
      CreatableResource.updatable?.should be_false

      UpdatableResource.creatable?.should be_false
      UpdatableResource.updatable?.should be_true

      GoCardless::Resource.creatable?.should be_false
      GoCardless::Resource.updatable?.should be_false
    end
  end

  describe "sub_resource_uri methods" do
    let(:test_resource) { Class.new(GoCardless::Resource) }
    before :each do
      @attrs = {
        'sub_resource_uris' => {
          'bills' => 'https://test.com/api/bills/?merchant_id=1'
        }
      }
    end

    it "are defined on instances" do
      r = test_resource.new(@attrs)
      r.should respond_to :bills
    end

    it "aren't defined for other instances of the class" do
      test_resource.new(@attrs)
      resource = test_resource.new
      resource.should_not respond_to :bills
    end

    it "use the correct uri path" do
      client = double()
      client.should_receive(:api_get).with('/api/bills/', anything).and_return([])
      r = test_resource.new_with_client(client, @attrs)
      r.bills
    end

    it "strips the api prefix from the path" do
      client = double()
      client.should_receive(:api_get).with('/bills/', anything).and_return([])
      uris = {'bills' => 'https://test.com/api/v123/bills/'}
      r = test_resource.new_with_client(client, 'sub_resource_uris' => uris)
      r.bills
    end

    it "use the correct query string params" do
      client = double()
      client.should_receive(:api_get).with(anything, 'merchant_id' => '1').and_return([])
      r = test_resource.new_with_client(client, @attrs)
      r.bills
    end

    it "adds provided params to existing query string params" do
      client = double()
      params = { 'merchant_id' => '1', :amount => '10.00' }
      client.should_receive(:api_get).with(anything, params).and_return([])
      r = test_resource.new_with_client(client, @attrs)
      r.bills(:amount => '10.00')
    end

    it "adds provided params when there are no existing query string params" do
      client = double()
      params = { :source_id => 'xxx' }
      client.should_receive(:api_get).with(anything, params).and_return([])
      r = test_resource.new_with_client(client, {
        'sub_resource_uris' => {
          'bills' => 'https://test.com/merchants/1/bills'
        }
      })
      r.bills(:source_id => 'xxx')
    end

    it "return instances of the correct resource class" do
      client = double(:api_get => [{:id => 1}])
      r = test_resource.new_with_client(client, @attrs)
      ret = r.bills
      ret.should be_a Array
      ret.first.should be_a GoCardless::Bill
    end
  end
end

