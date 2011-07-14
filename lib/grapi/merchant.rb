module Grapi
  class Merchant < Resource
    attr_accessor :name, :description, :email, :first_name, :last_name
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
  end
end
