module Grapi
  class Merchant < Resource
    self.endpoint = '/merchants/:id'

    attr_accessor :name
    attr_accessor :description
    attr_accessor :email
    attr_accessor :first_name
    attr_accessor :last_name
    date_accessor :created_at

    def subscriptions
      @client.api_get("/merchants/#{self.id}/subscriptions").map do |attrs|
        Grapi::Subscription.from_hash(@client, attrs)
      end
    end

    def pre_authorizations
      @client.api_get("/merchants/#{self.id}/pre_authorizations").map do |attrs|
        Grapi::PreAuthorization.from_hash(@client, attrs)
      end
    end

    def users
      @client.api_get("/merchants/#{self.id}/users").map do |attrs|
        Grapi::User.from_hash(@client, attrs)
      end
    end

    def bills
      @client.api_get("/merchants/#{self.id}/bills").map do |attrs|
        Grapi::Bill.from_hash(@client, attrs)
      end
    end

    def payments
      @client.api_get("/merchants/#{self.id}/payments").map do |attrs|
        Grapi::Payment.from_hash(@client, attrs)
      end
    end
  end
end
