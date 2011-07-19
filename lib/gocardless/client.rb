require 'rubygems'
require 'json'
require 'oauth2'

module GoCardless
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

    # Generate the OAuth authorize url
    # @param [Hash] options parameters to be included in the url.
    #   +:redirect_uri+ is required.
    # @return [String] the authorize url
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

    # @return [String] a serialized form of the access token with its scope
    def access_token
      @access_token && "#{@access_token.token} #{@access_token.params[:scope]}"
    end

    # Set the client's access token
    #
    # @param [String] token a string with format <code>"#{token} #{scope}"</code>
    #   (as returned by {#access_token})
    def access_token=(token)
      token, scope = token.split(' ', 2)
      @access_token = OAuth2::AccessToken.new(@oauth_client, token)
      @access_token.params[:scope] = scope
    end

    # Issue an GET request to the API server
    #
    # @note this method is for internal use
    # @param [String] path the path that will be added to the API prefix
    # @param [Hash] params query string parameters
    # @return [Hash] hash the parsed response data
    def api_get(path, params = {})
      request(:get, "#{API_PATH}#{path}", :params => params).parsed
    end

    # Issue a POST request to the API server
    #
    # @note this method is for internal use
    # @param [String] path the path that will be added to the API prefix
    # @param [Hash] data a hash of data that will be sent as the request body
    # @return [Hash] hash the parsed response data
    def api_post(path, data = {})
      request(:post, "#{API_PATH}#{path}", :data => data).parsed
    end

    # Issue a PUT request to the API server
    #
    # @note this method is for internal use
    # @param [String] path the path that will be added to the API prefix
    # @param [Hash] data a hash of data that will be sent as the request body
    # @return [Hash] hash the parsed response data
    def api_put(path, data = {})
      request(:put, "#{API_PATH}#{path}", :data => data).parsed
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

    # Create a new bill under a given pre-authorization
    # @see PreAuthorization#create_bill
    #
    # @param [Hash] attrs must include +:pre_authorization_id+ and +:amount+
    # @return [Bill] the created bill object
    def create_bill(attrs)
      Bill.new(self, attrs).save
    end

  private

    def request(method, path, opts = {})
      opts[:headers] = { 'Accept' => 'application/json' }
      opts[:headers]['Content-Type'] = 'application/json' unless method == :get
      opts[:body] = JSON.generate(opts[:data]) if !opts[:data].nil?
      @access_token.send(method, path, opts)
    end
  end
end

