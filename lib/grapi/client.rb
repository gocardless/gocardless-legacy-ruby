require 'rubygems'
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

    def get(path)
      @access_token.get(path, :headers => { :Accept => 'application/json' })
    end

    def api_get(path)
      get("/api/v1#{path}").parsed
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
  end
end

