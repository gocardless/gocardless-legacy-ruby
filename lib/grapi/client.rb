require 'rubygems'
require 'json'
require 'oauth2'

module Grapi
  class Client
    BASE_URL = 'http://localhost:3000'

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

    def request(method, path, data = nil)
      headers = { 'Accept' => 'application/json' }
      headers['Content-Type'] = 'application/json' unless method == :get
      body = JSON.generate(data) if !data.nil?
      @access_token.send(method, path, :headers => headers, :body => body)
    end

    def api_get(path)
      request(:get, "/api/v1#{path}").parsed
    end

    def api_post(path, data = {})
      request(:post, "/api/v1#{path}", data).parsed
    end

    def api_put(path, data = {})
      request(:put, "/api/v1#{path}", data).parsed
    end

    def merchant
      scope = @access_token.params[:scope].split
      perm = scope.select {|p| p.start_with?('manage_merchant:') }.first
      merchant_id = perm.split(':')[1]
      Merchant.from_hash(self, api_get("/merchants/#{merchant_id}"))
    end

    def subscription(id)
      Subscription.find(self, id)
    end

    def pre_authorization(id)
      PreAuthorization.find(self, id)
    end

    def user(id)
      User.find(self, id)
    end

    def bill(id)
      Bill.find(self, id)
    end

    def payment(id)
      Payment.find(self, id)
    end

    def create_bill(attrs)
      Bill.from_hash(self, attrs).save
    end
  end
end

