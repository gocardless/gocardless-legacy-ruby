module GoCardless
  class Subscription < Resource

    self.endpoint = '/subscriptions/:id'

    attr_accessor  :amount,
                   :currency,
                   :interval_length,
                   :interval_unit,
                   :name,
                   :description,
                   :status,
                   :setup_fee

    reference_accessor :merchant_id, :user_id

    date_accessor :start_at, :expires_at, :created_at, :next_interval_start


    def cancel!
      path = self.class.endpoint.gsub(':id', id.to_s) + '/cancel'
      client.api_put(path)
    end

    def inactive?
      status == 'inactive'
    end

    def active?
      status == 'active'
    end

    def cancelled?
      status == 'cancelled'
    end

    def expired?
      status == 'expired'
    end

  end
end

