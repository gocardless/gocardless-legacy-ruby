require 'spec_helper'

describe GoCardless::Client do
  before :each do
    @app_id = 'abc'
    @app_secret = 'xyz'
    @redirect_uri = 'http://test.com/cb'
  end

  describe ".base_url" do
    it "and_return the correct url for the production environment" do
      GoCardless.environment = :production
      expect(GoCardless::Client.base_url).to eq('https://gocardless.com')
    end

    it "and_return the correct url for the sandbox environment" do
      GoCardless.environment = :sandbox
      expect(GoCardless::Client.base_url).to eq('https://sandbox.gocardless.com')
    end

    it "and_return the correct url when it's set manually" do
      GoCardless::Client.base_url = 'https://abc.gocardless.com'
      expect(GoCardless::Client.base_url).to eq('https://abc.gocardless.com')
    end
  end

  describe "#new" do
    it "without an app id should raise an error" do
      expect do
        GoCardless::Client.new({:app_secret => @app_secret})
      end.to raise_exception(GoCardless::ClientError)
    end

    it "without an app_secret should raise an error" do
      expect do
        GoCardless::Client.new({:app_id => @app_id})
      end.to raise_exception(GoCardless::ClientError)
    end

    it "does not raise an error if the credentials are provided as environment variables" do
      expect(ENV).to receive(:[]).with('GOCARDLESS_APP_ID').and_return(@app_id)
      expect(ENV).to receive(:[]).with('GOCARDLESS_APP_SECRET').and_return(@app_secret)

      GoCardless::Client.new
    end

    it "sets a merchant id if it's given" do
      client = GoCardless::Client.new({
        :app_id      => @app_id,
        :app_secret  => @app_secret,
        :merchant_id => 'xyz'
      })
      expect(client.send('merchant_id')).to eq('xyz')
    end
  end

  before do
    @client = GoCardless::Client.new({:app_id => @app_id, :app_secret => @app_secret})
  end

  describe "#authorize_url" do
    it "fails without a redirect uri" do
      expect { @client.authorize_url }.to raise_exception(ArgumentError)
    end

    it "generates the authorize url correctly" do
      url = URI.parse(@client.authorize_url(:redirect_uri => @redirect_uri))
      query = CGI.parse(url.query)
      expect(query['response_type'].first).to eq('code')
      expect(query['redirect_uri'].first).to eq(@redirect_uri)
      expect(query['client_id'].first).to eq(@app_id)
    end

    it "includes the cancel uri if present" do
      cancel_uri = 'http://test/cancel'
      url = URI.parse(@client.authorize_url(
        :redirect_uri => @redirect_uri,
        :cancel_uri   => cancel_uri
      ))
      query = CGI.parse(url.query)
      expect(query['cancel_uri'].first).to eq(cancel_uri)
    end

    it "encodes prefilling parameters correctly" do
      params = {:merchant => {:user => {:email => "a@b.com"}}}
      url = @client.authorize_url(params.merge(:redirect_uri => @redirect_uri))
      encoded_key = GoCardless::Utils.percent_encode('merchant[user][email]')
      expect(URI.parse(url).query).to match /#{encoded_key}=a%40b\.com/
    end
  end

  describe "#fetch_access_token" do
    access_token_url = "#{GoCardless::Client.base_url}/oauth/access_token"

    it "fails without a redirect uri" do
      expect do
        @client.fetch_access_token('code', {})
      end.to raise_exception(ArgumentError)
    end

    describe "with valid params" do
      let(:oauth_client) { @client.instance_variable_get(:@oauth_client) }
      let(:fake_token) do
        double(:params => {'scope' => 'manage_merchant:x'}, :token  => 'abc')
      end

      before { allow(oauth_client.auth_code).to receive(:get_token).and_return(fake_token) }

      it "calls correct method with correct args" do
        auth_code = 'fakecode'

        expect(oauth_client.auth_code).to receive(:get_token).with(
          auth_code, hash_including(:redirect_uri => @redirect_uri)
        ).and_return(fake_token)

        @client.fetch_access_token(auth_code, {:redirect_uri => @redirect_uri})
      end

      it "sets @access_token" do
        expect(@client.instance_variable_get(:@access_token)).to be_nil
        @client.fetch_access_token('code', {:redirect_uri => @redirect_uri})
        expect(@client.instance_variable_get(:@access_token)).to eq(fake_token)
      end

      it "sets @merchant_id" do
        expect(@client.instance_variable_get(:@merchant_id)).to be_nil
        @client.fetch_access_token('code', {:redirect_uri => @redirect_uri})
        expect(@client.instance_variable_get(:@merchant_id)).to eq('x')
      end
    end
  end

  describe "#access_token" do
    it "serializes access token correctly" do
      oauth_client = @client.instance_variable_get(:@oauth_client)
      token = OAuth2::AccessToken.new(oauth_client, 'TOKEN123')
      token.params['scope'] = 'a:1 b:2'
      @client.instance_variable_set(:@access_token, token)

      expect(@client.access_token).to eq('TOKEN123 a:1 b:2')
    end

    it "and_return nil when there's no token" do
      expect(@client.access_token).to be_nil
    end
  end

  describe "#access_token=" do
    before { allow(@client).to receive(:warn) }

    it "deserializes access token correctly" do
      @client.access_token = 'TOKEN123 a:1 b:2'
      token = @client.instance_variable_get(:@access_token)
      expect(token.token).to eq('TOKEN123')
      expect(token.params['scope']).to eq('a:1 b:2')
    end

    it "pulls out the merchant_id when present" do
      @client.access_token = 'TOKEN123 manage_merchant:xyz'
      expect(@client.send('merchant_id')).to eq('xyz')
    end

    it "issues a deprecation warning when the scope is present" do
      expect(@client).to receive(:warn)
      @client.access_token = 'TOKEN123 manage_merchant:xyz'
    end

    it "doesn't issue a deprecation warning when the scope is missing" do
      expect(@client).to receive(:warn).never
      @client.access_token = 'TOKEN123'
    end

    it "ignores 'bearer' if it is present at the start of the string" do
      @client.access_token = 'Bearer TOKEN manage_merchant:123'
      token = @client.instance_variable_get(:@access_token)
      expect(token.token).to eq('TOKEN')
      expect(token.params['scope']).to eq('manage_merchant:123')
    end
  end

  describe "#api_get" do
    it "uses the correct path prefix" do
      @client.access_token = 'TOKEN123'
      token = @client.instance_variable_get(:@access_token)
      r = double
      allow(r).to receive(:parsed)
      expect(token).to receive(:get) { |p,o| p =~ %r|/api/v1/test| }.and_return(r)
      @client.api_get('/test')
    end

    it "fails without an access_token" do
      expect { @client.api_get '/' }.to raise_exception GoCardless::ClientError
    end
  end

  describe "#api_post" do
    it "encodes data to json" do
      @client.access_token = 'TOKEN123'
      token = @client.instance_variable_get(:@access_token)
      r = double
      allow(r).to receive(:parsed)
      expect(token).to receive(:post) { |p,opts| opts[:body] == '{"a":1}' }.and_return(r)
      @client.api_post('/test', {:a => 1})
    end

    it "fails without an access_token" do
      expect { @client.api_post '/' }.to raise_exception GoCardless::ClientError
    end
  end

  describe "#api_delete" do
    it "encodes data to json" do
      @client.access_token = 'TOKEN123'
      token = @client.instance_variable_get(:@access_token)
      r = double
      allow(r).to receive(:parsed)
      expect(token).to receive(:delete) { |p,opts| opts[:body] == '{"a":1}' }.and_return(r)
      @client.api_delete('/test', {:a => 1})
    end

    it "fails without an access_token" do
      expect { @client.api_delete '/' }.to raise_exception GoCardless::ClientError
    end
  end

  describe "#merchant" do
    it "looks up the correct merchant" do
      @client.access_token = 'TOKEN'
      @client.merchant_id = '123'
      response = double
      expect(response).to receive(:parsed)

      token = @client.instance_variable_get(:@access_token)
      merchant_url = '/api/v1/merchants/123'
      expect(token).to receive(:get) { |p,o| p == merchant_url }.and_return response

      allow(GoCardless::Merchant).to receive(:new_with_client)

      @client.merchant
    end

    it "creates a Merchant object" do
      @client.access_token = 'TOKEN'
      @client.merchant_id = '123'
      response = double
      expect(response).to receive(:parsed).and_return({:name => 'test', :id => 123})

      token = @client.instance_variable_get(:@access_token)
      expect(token).to receive(:get).and_return response

      merchant = @client.merchant
      expect(merchant).to be_an_instance_of GoCardless::Merchant
      expect(merchant.id).to eq(123)
      expect(merchant.name).to eq('test')
    end
  end

  %w(subscription pre_authorization user bill).each do |resource|
    describe "##{resource}" do
      it "and_return the correct #{GoCardless::Utils.camelize(resource)} object" do
        @client.access_token = 'TOKEN'
        @client.merchant_id = '123'
        stub_get(@client, {:id => 123})
        obj = @client.send(resource, 123)
        expect(obj).to be_a GoCardless.const_get(GoCardless::Utils.camelize(resource))
        expect(obj.id).to eq(123)
      end
    end
  end

  it "#sign_params signs pararmeter hashes correctly" do
    @client.instance_variable_set(:@app_secret, 'testsecret')
    params = {:test => true}
    sig = '6e4613b729ce15c288f70e72463739feeb05fc0b89b55d248d7f259b5367148b'
    expect(@client.send(:sign_params, params)[:signature]).to eq(sig)
  end

  describe "#signature_valid?" do
    before(:each) { @params = { :x => 'y', :a => 'b' } }

    it "succeeds with a valid signature" do
      params = @client.send(:sign_params, @params)
      expect(@client.send(:signature_valid?, params)).to be_truthy
    end

    it "fails with an invalid signature" do
      params = {:signature => 'invalid'}.merge(@params)
      expect(@client.send(:signature_valid?, params)).to be_falsey
    end
  end

  describe "#confirm_resource" do
    before :each do
      @params = {
        :resource_id   => '1',
        :resource_uri  => 'a',
        :resource_type => 'subscription',
      }
    end

    it "doesn't confirm the resource when the signature is invalid" do
      expect(@client).to receive(:request).never
      @client.confirm_resource({:signature => 'xxx'}.merge(@params)) rescue nil
    end

    it "fails when the signature is invalid" do
      expect do
        @client.confirm_resource({:signature => 'xxx'}.merge(@params))
      end.to raise_exception GoCardless::SignatureError
    end

    it "confirms the resource when the signature is valid" do
      # Once for confirm, once to fetch result
      expect(@client).to receive(:request).twice.and_return(double(:parsed => {}))
      @client.confirm_resource(@client.send(:sign_params, @params))
    end

    it "and_return the correct object when the signature is valid" do
      allow(@client).to receive(:request).and_return(double(:parsed => {}))
      subscription = GoCardless::Subscription.new_with_client @client
      expect(GoCardless::Subscription).to receive(:find_with_client).and_return subscription

      # confirm_resource should use the Subcription class because
      # the :response_type is set to subscription
      resource = @client.confirm_resource(@client.send(:sign_params, @params))
      expect(resource).to be_a GoCardless::Subscription
    end

    it "includes valid http basic credentials" do
      allow(GoCardless::Subscription).to receive(:find_with_client)
      auth = 'Basic YWJjOnh5eg=='
      expect(@client).to receive(:request).once { |type, path, opts|
        expect(opts).to include :headers
        expect(opts[:headers]).to include 'Authorization'
        expect(opts[:headers]['Authorization']).to eq(auth)
      }
      @client.confirm_resource(@client.send(:sign_params, @params))
    end

    it "works with string params" do
      allow(@client).to receive(:request)
      allow(GoCardless::Subscription).to receive(:find_with_client)
      params = Hash[@params.dup.map { |k,v| [k.to_s, v] }]
      params.keys.each { |p| expect(p).to be_a String }
      # No ArgumentErrors should be raised
      @client.confirm_resource(@client.send(:sign_params, params))
    end
  end

  describe "#response_params_valid?" do
    before :each do
      @params = {
        :resource_id   => '1',
        :resource_uri  => 'a',
        :resource_type => 'subscription',
      }
    end

    [:resource_id, :resource_uri, :resource_type].each do |param|
      it "fails when :#{param} is missing" do
        params = @params.tap { |d| d.delete(param) }
        expect do
          @client.response_params_valid? params
        end.to raise_exception ArgumentError
      end
    end

    it "does not fail when keys are strings in a HashWithIndiferentAccess" do
      params = {'resource_id' => 1,
                'resource_uri' => 'a',
                'resource_type' => 'subscription',
                'signature' => 'foo'}
      params_indifferent_access = HashWithIndifferentAccess.new(params)
      expect do
        @client.response_params_valid? params_indifferent_access
      end.to_not raise_exception
    end

    it "rejects other params not required for the signature" do
      expect(@client).to receive(:signature_valid?) { |hash|
        !hash.keys.include?(:foo) && !hash.keys.include?('foo')
      }.and_return(true)

      params = @client.send(:sign_params, @params).merge('foo' => 'bar')
      @client.response_params_valid?(params)
    end

    it "and_return false when the signature is invalid" do
      params = {:signature => 'xxx'}.merge(@params)
      expect(@client.response_params_valid?(params)).to be_falsey
    end

    it "and_return true when the signature is valid" do
      params = @client.send(:sign_params, @params)
      expect(@client.response_params_valid?(params)).to be_truthy
    end
  end

  it "#generate_nonce should generate a random string" do
    expect(@client.send(:generate_nonce)).not_to eq(@client.send(:generate_nonce))
  end

  describe "#new_limit_url" do
    before(:each) do
      @merchant_id = '123'
      @client.access_token = "TOKEN"
      @client.merchant_id  = @merchant_id
    end

    def get_params(url)
      Hash[CGI.parse(URI.parse(url).query).map{ |k,v| [k, v.first] }]
    end

    it "should use the correct path" do
      url = @client.send(:new_limit_url, :test_limit, {})
      expect(URI.parse(url).path).to eq('/connect/test_limits/new')
    end

    it "should include the params in the URL query" do
      params = { 'a' => '1', 'b' => '2' }
      url = @client.send(:new_limit_url, :subscription, params)
      url_params = get_params(url)
      params.each do |key, value|
        expect(url_params["subscription[#{key}]"]).to eq(value)
      end
    end

    it "should include the state in the URL query" do
      params = { 'a' => '1', 'b' => '2', :state => "blah" }
      url = @client.send(:new_limit_url, :subscription, params)
      expect(get_params(url)["state"]).to eq("blah")
    end

    it "should include the redirect_uri in the URL query" do
      params = { 'a' => '1', 'b' => '2', :redirect_uri => "http://www.google.com" }
      url = @client.send(:new_limit_url, :subscription, params)
      expect(get_params(url)["redirect_uri"]).to eq("http://www.google.com")
    end

    it "should include the cancel_uri in the URL query" do
      params = { 'a' => '1', 'b' => '2', :cancel_uri => "http://www.google.com" }
      url = @client.send(:new_limit_url, :subscription, params)
      expect(get_params(url)["cancel_uri"]).to eq("http://www.google.com")
    end

    it "should add merchant_id to the limit" do
      url = @client.send(:new_limit_url, :subscription, {})
      expect(get_params(url)['subscription[merchant_id]']).to eq(@merchant_id)
    end

    it "should include a valid signature" do
      params = get_params(@client.send(:new_limit_url, :subscription, :x => 1))
      expect(params.key?('signature')).to be_truthy
      sig = params.delete('signature')
      expect(sig).to eq(@client.send(:sign_params, params.clone)[:signature])
    end

    it "should include a nonce" do
      params = get_params(@client.send(:new_limit_url, :subscription, :x => 1))
      expect(params['nonce']).to be_a String
    end

    it "should include a client_id" do
      params = get_params(@client.send(:new_limit_url, :subscription, :x => 1))
      expect(params['client_id']).to eq(@client.instance_variable_get(:@app_id))
    end

    it "should include a timestamp" do
      # Time.now returning Pacific time
      time = Time.parse('Sat Jan 01 2011 00:00:00 -0800')
      expect(Time).to receive(:now).and_return time
      params = get_params(@client.send(:new_limit_url, :subscription, :x => 1))
      # Check that timezone is ISO formatted UTC
      expect(params['timestamp']).to eq("2011-01-01T08:00:00Z")
    end
  end

  describe "#merchant_id" do
    it "and_return the merchant id when an access token is set" do
      @client.merchant_id = '123'
      expect(@client.send(:merchant_id)).to eq('123')
    end

    it "fails if there's no access token" do
      expect do
        @client.send(:merchant_id)
      end.to raise_exception GoCardless::ClientError
    end
  end

  describe "#webhook_valid?" do
    it "and_return false when the webhook signature is invalid" do
      expect(@client.webhook_valid?({:some => 'stuff', :signature => 'invalid'})).
        to be_falsey
    end

    it "and_return true when the webhook signature is valid" do
      valid_signature = '175e814f0f64e5e86d41fb8fe06a857cedda715a96d3dc3d885e6d97dbeb7e49'
      expect(@client.webhook_valid?({:some => 'stuff', :signature => valid_signature})).
        to be_truthy
    end
  end

  describe "base_url" do
    it "and_return a custom base URL when one has been set" do
      @client.base_url = 'http://test.com/'
      expect(@client.base_url).to eq('http://test.com/')
    end

    it "and_return the default value when base_url is not set for the instance" do
      allow(GoCardless::Client).to receive_messages(:base_url => 'http://gc.com/')
      expect(@client.base_url).to eq('http://gc.com/')
    end
  end
end

