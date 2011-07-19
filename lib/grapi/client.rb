require 'rubygems'
require 'json'
require 'oauth2'

module Grapi
  class Client
    BASE_URL = 'http://localhost:3000'
    API_PATH = '/api/v1'

    def initialize(app_id, app_secret, token = nil)
      @app_id = app_id
      @app_secret = app_secret
      @oauth_client = OAuth2::Client.new(app_id, app_secret, :site => BASE_URL,
                                         :token_url => '/oauth/access_token')
      self.access_token = token if token
    end

    def authorize_url(options)
      raise ArgumentError, ':redirect_uri required' unless options[:redirect_uri]
      params = {:client_id => @app_id, :response_type => 'code'}
      @oauth_client.authorize_url(params.merge(options))
    end

    # @method fetch_access_token(auth_code, options)
    # @param [String] auth_code to exchange for the access_token
    # @return [String] the access_token required to make API calls to resources
    def fetch_access_token(auth_code, options)
      raise ArgumentError, ':redirect_uri required' unless options[:redirect_uri]
      @access_token = @oauth_client.auth_code.get_token(auth_code, options)
    end

    def access_token
      @access_token && "#{@access_token.token} #{@access_token.params[:scope]}"
    end

    def access_token=(token)
      token, scope = token.split(' ', 2)
      @access_token = OAuth2::AccessToken.new(@oauth_client, token)
      @access_token.params[:scope] = scope
    end

    # @method api_get(path) fetches data at the specified path
    # @param [String] TODO: document me
    # @return [Hash] hash of data at the request path
    def api_get(path)
      request(:get, "#{API_PATH}#{path}").parsed
    end

    def api_post(path, data = {})
      request(:post, "#{API_PATH}#{path}", data).parsed
    end

    def api_put(path, data = {})
      request(:put, "#{API_PATH}#{path}", data).parsed
    end

    # @method merchant
    # @return [Merchant] the merchant associated with the client's access token
    def merchant
      scope = @access_token.params[:scope].split
      perm = scope.select {|p| p.start_with?('manage_merchant:') }.first
      merchant_id = perm.split(':')[1]
      Merchant.new(self, api_get("/merchants/#{merchant_id}"))
    end

    # @method subscripton(id)
    # @param [String] id of the subscription
    # @return [Subscription] the subscription matching the id requested
    def subscription(id)
      Subscription.find(self, id)
    end

    # @method pre_authorization(id)
    # @param [String] id of the pre_authorization
    # @return [PreAuthorization] the pre_authorization matching the id requested
    def pre_authorization(id)
      PreAuthorization.find(self, id)
    end

    # @method user(id)
    # @param [String] id of the user
    # @return [User] the User matching the id requested
    def user(id)
      User.find(self, id)
    end

    # @method bill(id)
    # @param [String] id of the bill
    # @return [Bill] the Bill matching the id requested
    def bill(id)
      Bill.find(self, id)
    end

    # @method payment(id)
    # @param [String] id of the payment
    # @return [Payment] the payment matching the id requested
    def payment(id)
      Payment.find(self, id)
    end

    def create_bill(attrs)
      Bill.new(self, attrs).save
    end

  private

    def request(method, path, data = nil)
      headers = { 'Accept' => 'application/json' }
      headers['Content-Type'] = 'application/json' unless method == :get
      body = JSON.generate(data) if !data.nil?
      @access_token.send(method, path, :headers => headers, :body => body)
    end
  end
end

