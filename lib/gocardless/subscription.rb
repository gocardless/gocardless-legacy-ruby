module GoCardless
  class Subscription < Resource

    self.endpoint = '/subscriptions/:id'

    reference_accessor :merchant_id, :user_id

    date_accessor :start_at, :expires_at, :created_at, :next_interval_start

    def cancel!
      path = self.class.endpoint.gsub(':id', id.to_s) + '/cancel'
      client.api_put(path)
    end

  end
end

