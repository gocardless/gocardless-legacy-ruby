require 'multi_json'
require 'oauth2'
require 'openssl'
require 'uri'
require 'cgi'
require 'time'
require 'base64'

module GoCardless
  class Client
    BASE_URLS = {
      :production => 'https://gocardless.com',
      :sandbox    => 'https://sandbox.gocardless.com',
    }
    API_PATH = '/api/v1'

    class << self
      def base_url=(url)
        @base_url = url.sub(%r|/$|, '')
      end

      def base_url
        @base_url || BASE_URLS[GoCardless.environment || :production]
      end
    end

    def initialize(args = {})
      Utils.symbolize_keys! args
      @app_id = args.fetch(:app_id) { ENV['GOCARDLESS_APP_ID'] }
      @app_secret = args.fetch(:app_secret) { ENV['GOCARDLESS_APP_SECRET'] }
      raise ClientError.new("You must provide an app_id") unless @app_id
      raise ClientError.new("You must provide an app_secret") unless @app_secret

      @oauth_client = OAuth2::Client.new(@app_id, @app_secret,
                                         :site => self.base_url,
                                         :token_url => '/oauth/access_token')

      self.access_token = args[:token] if args[:token]
      @merchant_id = args[:merchant_id] if args[:merchant_id]
    end

    # Generate the OAuth authorize url
    #
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
      # Faraday doesn't flatten params in this case (Faraday issue #115)
      options = Hash[Utils.flatten_params(options)]
      @oauth_client.authorize_url(params.merge(options))
    end
    alias :new_merchant_url :authorize_url

    # Exchange the authorization code for an access token
    #
    # @param [String] auth_code to exchange for the access_token
    # @return [String] the access_token required to make API calls to resources
    def fetch_access_token(auth_code, options)
      raise ArgumentError, ':redirect_uri required' unless options[:redirect_uri]
      # Exchange the auth code for an access token
      @access_token = @oauth_client.auth_code.get_token(auth_code, options)

      # Use the scope to figure out which merchant we're managing
      scope = @access_token.params[:scope] || @access_token.params['scope']
      set_merchant_id_from_scope(scope)

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
    # @param [String] token a string with format <code>"#{token}"</code>
    #   (as returned by {#access_token})
    def access_token=(token)
      token, scope = token.sub(/^bearer\s+/i, '').split(' ', 2)
      if scope
        warn "[DEPRECATION] (gocardless-ruby) merchant_id is now a separate " +
             "attribute, the manage_merchant scope should no longer be " +
             "included in the 'token' attribute. See http://git.io/G9y37Q " +
             "for more info."
      else
        scope = ''
      end

      @access_token = OAuth2::AccessToken.new(@oauth_client, token)
      @access_token.params['scope'] = scope

      set_merchant_id_from_scope(scope) unless @merchant_id
    end

    # Return the merchant id, throwing a proper error if it's missing.
    def merchant_id
      raise ClientError, 'No merchant id set' unless @merchant_id
      @merchant_id
    end

    attr_writer :merchant_id

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

    # Issue a DELETE request to the API server
    #
    # @note this method is for internal use
    # @param [String] path the path that will be added to the API prefix
    # @param [Hash] data a hash of data that will be sent as the request body
    # @return [Hash] hash the parsed response data
    def api_delete(path, data = {})
      request(:delete, "#{API_PATH}#{path}", :data => data).parsed
    end

    # @method merchant
    # @return [Merchant] the merchant associated with the client's access token
    def merchant
      raise ClientError, 'Access token missing' unless @access_token
      Merchant.new_with_client(self, api_get("/merchants/#{merchant_id}"))
    end

    # @method subscripton(id)
    # @param [String] id of the subscription
    # @return [Subscription] the subscription matching the id requested
    def subscription(id)
      Subscription.find_with_client(self, id)
    end

    # @method pre_authorization(id)
    # @param [String] id of the pre_authorization
    # @return [PreAuthorization] the pre_authorization matching the id requested
    def pre_authorization(id)
      PreAuthorization.find_with_client(self, id)
    end

    # @method user(id)
    # @param [String] id of the user
    # @return [User] the User matching the id requested
    def user(id)
      User.find_with_client(self, id)
    end

    # @method bill(id)
    # @param [String] id of the bill
    # @return [Bill] the Bill matching the id requested
    def bill(id)
      Bill.find_with_client(self, id)
    end

    # @method payment(id)
    # @param [String] id of the payment
    # @return [Payment] the payment matching the id requested
    def payment(id)
      Payment.find_with_client(self, id)
    end

    # Create a new bill under a given pre-authorization
    # @see PreAuthorization#create_bill
    #
    # @param [Hash] attrs must include +:pre_authorization_id+ and +:amount+
    # @return [Bill] the created bill object
    def create_bill(attrs)
      Bill.new_with_client(self, attrs).save
    end

    # Generate the URL for creating a new subscription. The parameters passed
    # in define various attributes of the subscription. Redirecting a user to
    # the resulting URL will show them a page where they can approve or reject
    # the subscription described by the parameters. Note that this method
    # automatically includes the nonce, timestamp and signature.
    #
    # @param [Hash] params the subscription parameters
    # @return [String] the generated URL
    def new_subscription_url(params)
      new_limit_url(:subscription, params)
    end

    # Generate the URL for creating a new pre authorization. The parameters
    # passed in define various attributes of the pre authorization. Redirecting
    # a user to the resulting URL will show them a page where they can approve
    # or reject the pre authorization described by the parameters. Note that
    # this method automatically includes the nonce, timestamp and signature.
    #
    # @param [Hash] params the pre authorization parameters
    # @return [String] the generated URL
    def new_pre_authorization_url(params)
      new_limit_url(:pre_authorization, params)
    end

    # Generate the URL for creating a new bill. The parameters passed in define
    # various attributes of the bill. Redirecting a user to the resulting URL
    # will show them a page where they can approve or reject the bill described
    # by the parameters. Note that this method automatically includes the
    # nonce, timestamp and signature.
    #
    # @param [Hash] params the bill parameters
    # @return [String] the generated URL
    def new_bill_url(params)
      new_limit_url(:bill, params)
    end

    # Confirm a newly-created subscription, pre-authorzation or one-off
    # payment. This method also checks that the resource response data includes
    # a valid signature and will raise a {SignatureError} if the signature is
    # invalid.
    #
    # @param [Hash] params the response parameters returned by the API server
    # @return [Resource] the confirmed resource object
    def confirm_resource(params)
      params = prepare_params(params)

      if signature_valid?(params)
        data = {
          :resource_id => params[:resource_id],
          :resource_type => params[:resource_type],
        }

        credentials = Base64.encode64("#{@app_id}:#{@app_secret}")
        credentials = credentials.gsub(/\s/, '')
        headers = {
          'Authorization' => "Basic #{credentials}"
        }
        request(:post, "#{api_url}/confirm", :data => data,
                                                  :headers => headers)

        # Initialize the correct class according to the resource's type
        klass = GoCardless.const_get(Utils.camelize(params[:resource_type]))
        klass.find_with_client(self, params[:resource_id])
      else
        raise SignatureError, 'An invalid signature was detected'
      end
    end


    # Check that resource response data includes a valid signature.
    #
    # @param [Hash] params the response parameters returned by the API server
    # @return [Boolean] true when valid, false otherwise
    def response_params_valid?(params)
      params = prepare_params(params)

      signature_valid?(params)
    end


    # Validates the payload contents of a webhook request.
    #
    # @param [Hash] params the contents of payload of the webhook
    # @return [Boolean] true when valid, false otherwise
    def webhook_valid?(params)
      signature_valid?(params)
    end

    # Set the base URL for this client instance. Overrides all other settings
    # (setting the environment globally, setting the Client class's base URL).
    #
    # @param [String] url the base URL to use
    def base_url=(url)
      @base_url = url
    end

    # Get the base URL for the client. If set manually for the instance, that
    # URL will be returned. Otherwise, it will be deferred to
    # +Client.base_url+.
    def base_url
      @base_url || self.class.base_url
    end

    def api_url
      "#{base_url}#{API_PATH}"
    end

  private

    # Pull the merchant id out of the access scope
    def set_merchant_id_from_scope(scope)
      perm = scope.split.select {|p| p.start_with?('manage_merchant:') }.first
      @merchant_id = perm.split(':')[1] if perm
    end

    # Send a request to the GoCardless API servers
    #
    # @param [Symbol] method the HTTP method to use (e.g. +:get+, +:post+)
    # @param [String] path the path fragment of the URL
    # @option [Hash] opts query string parameters
    def request(method, path, opts = {})
      raise ClientError, 'Access token missing' unless @access_token

      opts[:headers] = {} if opts[:headers].nil?
      opts[:headers]['Accept'] = 'application/json'
      opts[:headers]['Content-Type'] = 'application/json' unless method == :get
      opts[:headers]['User-Agent'] = "gocardless-ruby/v#{GoCardless::VERSION}"
      opts[:body] = MultiJson.encode(opts[:data]) if !opts[:data].nil?

      # Reset the URL in case the environment / base URL has been changed.
      @oauth_client.site = base_url

      header_keys = opts[:headers].keys.map(&:to_s)
      if header_keys.map(&:downcase).include?('authorization')
        @oauth_client.request(method, path, opts)
      else
        @access_token.send(method, path, opts)
      end
    rescue OAuth2::Error => err
      raise GoCardless::ApiError.new(err.response)
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
      params[:signature] = Utils.sign_params(params, @app_secret)
      params
    end

    # Prepare a Hash of parameters for signing. Presence of required
    # parameters is checked and the others are discarded.
    #
    # @param [Hash] params the parameters to be prepared for signing
    # @return [Hash] the prepared parameters
    def prepare_params(params)
      # Create a new hash in case is a HashWithIndifferentAccess (keys are
      # always a String)
      params = Utils.symbolize_keys(Hash[params])
      # Only pull out the relevant parameters, other won't be included in the
      # signature so will cause false negatives
      keys = [:resource_id, :resource_type, :resource_uri, :state, :signature]
      params = Hash[params.select { |k,v| keys.include? k }]
      (keys - [:state]).each do |key|
        raise ArgumentError, "Parameters missing #{key}" if !params.key?(key)
      end
      params
    end

    # Check if a hash's :signature is valid
    #
    # @param [Hash] params the parameters to check
    # @return [Boolean] whether or not the signature is valid
    def signature_valid?(params)
      params = params.clone
      signature = params.delete(:signature)
      sign_params(params)[:signature] == signature
    end

    # Generate a random base64-encoded string
    #
    # @return [String] a randomly generated string
    def generate_nonce
      Base64.encode64((0...45).map { rand(256).chr }.join).strip
    end

    # Generate the URL for creating a limit of type +type+, including the
    # provided params, nonce, timestamp and signature
    #
    # @param [Symbol] type the limit type (+:subscription+, etc)
    # @param [Hash] params the bill parameters
    # @return [String] the generated URL
    def new_limit_url(type, limit_params)
      url = URI.parse("#{base_url}/connect/#{type}s/new")

      limit_params[:merchant_id] = merchant_id
      redirect_uri = limit_params.delete(:redirect_uri)
      cancel_uri = limit_params.delete(:cancel_uri)
      state = limit_params.delete(:state)

      params = {
        :nonce       => generate_nonce,
        :timestamp   => Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%SZ'),
        :client_id   => @app_id,
        type         => limit_params,
      }
      params[:redirect_uri] = redirect_uri unless redirect_uri.nil?
      params[:cancel_uri] = cancel_uri unless cancel_uri.nil?
      params[:state] = state unless state.nil?

      sign_params(params)

      url.query = Utils.normalize_params(params)
      url.to_s
    end
  end
end

