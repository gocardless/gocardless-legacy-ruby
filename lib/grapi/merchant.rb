require 'date'

module Grapi
  class Merchant < Resource
    attr_accessor :name, :uri, :id, :description, :email, :first_name,
                  :last_name
    date_accessor :created_at

    def subscriptions
      @client.api_get("/merchant/#{self.id}/subscriptions").map do |attrs|
        Grapi::Subscription.from_hash(@client, attrs)
      end
    end
  end
end
