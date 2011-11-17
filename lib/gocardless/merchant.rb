module GoCardless
  class Merchant < Resource
    self.endpoint = '/merchants/:id'

    attr_accessor :name
    attr_accessor :description
    attr_accessor :email
    attr_accessor :first_name
    attr_accessor :last_name
    date_accessor :created_at

    def subscriptions(params = {})
      path = "/merchants/#{self.id}/subscriptions"
      @client.api_get(path, params).map do |attrs|
        GoCardless::Subscription.new_with_client(@client, attrs)
      end
    end

    def pre_authorizations(params = {})
      path = "/merchants/#{self.id}/pre_authorizations"
      @client.api_get(path, params).map do |attrs|
        GoCardless::PreAuthorization.new_with_client(@client, attrs)
      end
    end

    def users(params = {})
      path = "/merchants/#{self.id}/users"
      @client.api_get(path, params).map do |attrs|
        GoCardless::User.new_with_client(@client, attrs)
      end
    end

    def bills(params = {})
      path = "/merchants/#{self.id}/bills"
      @client.api_get(path, params).map do |attrs|
        GoCardless::Bill.new_with_client(@client, attrs)
      end
    end

    def payments(params = {})
      path = "/merchants/#{self.id}/payments"
      @client.api_get(path, params).map do |attrs|
        GoCardless::Payment.new_with_client(@client, attrs)
      end
    end
  end
end
