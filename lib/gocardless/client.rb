require 'rubygems'
require 'json'
require 'oauth2'
require 'openssl'

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
      params = {
        :client_id => @app_id,
        :response_type => 'code',
        :scope => 'manage_merchant'
      }
      @oauth_client.authorize_url(params.merge(options))
    end

    # @method fetch_access_token(auth_code, options)
    # @param [String] auth_code to exchange for the access_token
    # @return [String] the access_token required to make API calls to resources
    def fetch_access_token(auth_code, options)
      raise ArgumentError, ':redirect_uri required' unless options[:redirect_uri]
      @access_token = @oauth_client.auth_code.get_token(auth_code, options)
      self.access_token
    end

    # @return [String] a serialized form of the access token with its scope
    def access_token
      if @access_token
        scope = @access_token.params[:scope] || @access_token.params['scope']
        "#{@access_token.token} #{scope}".strip
      end
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

    # Add a signature to a Hash of parameters. The signature will be generated
    # from the app secret and the provided parameters, and should be used
    # whenever signed data needs to be sent to GoCardless (e.g. when creating
    # a new subscription). The signature will be added to the hash under the
    # key +:signature+.
    #
    # @param [Hash] params the parameters to sign
    # @return [Hash] the parameters with the new +:signature+ key
    def sign_params(params)
      msg = encode_params(params)
      digest = OpenSSL::Digest::Digest.new('sha256')
      params[:signature] = OpenSSL::HMAC.hexdigest(digest, @app_secret, msg)
      params
    end

    # Confirm a newly-created subscription, pre-authorzation or one-off
    # payment. This method also checks that the resource response data includes
    # a valid signature and will raise a {SignatureError} if the signature is
    # invalid.
    #
    # @param [Hash] params the response parameters returned by the API server
    # @return [Resource] the confirmed resource object
    def confirm_resource(params)
      # Only pull out the relevant parameters, other won't be included in the
      # signature so will cause false negatives
      keys = [:resource_id, :resource_type, :resource_uri, :state, :signature]
      params = Hash[params.select { |k,v| keys.include? k }]
      (keys - [:state]).each do |key|
        raise ArgumentError, "Parameters missing #{key}" if !params.key?(key)
      end

      if signature_valid?(params)
        data = { :resource_id => params[:resource_id] }
        request(:post, "#{BASE_URL}/confirm", :data => data)

        # Initialize the correct class according to the resource's type
        klass = GoCardless.const_get(params[:resource_type].camelize)
        klass.find(self, params[:resource_id])
      else
        raise SignatureError, 'An invalid signature was detected'
      end
    end

  private

    # Convert a hash into query-string style parameters
    def encode_params(params, ns = nil)
      params.map do |key,val|
        key = ns ? "#{ns}[#{key.is_a?(Integer) ? '' : key.to_s}]" : key.to_s
        case val
        when Hash
          encode_params(val, key)
        when Array
          encode_params(Hash[(1..val.length).zip(val)], key)
        else
          "#{CGI.escape(key)}=#{CGI.escape(val.to_s)}"
        end
      end.sort * '&'
    end

    def request(method, path, opts = {})
      opts[:headers] = { 'Accept' => 'application/json' }
      opts[:headers]['Content-Type'] = 'application/json' unless method == :get
      opts[:body] = JSON.generate(opts[:data]) if !opts[:data].nil?
      @access_token.send(method, path, opts)
    rescue OAuth2::Error => err
      raise GoCardless::ApiError.new(err.response)
    end

    # Check if a hash's :signature is valid
    def signature_valid?(params)
      params = params.clone
      signature = params.delete(:signature)
      sign_params(params)[:signature] == signature
    end
  end
end

