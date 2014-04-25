module GoCardless
  class Subscription < Resource

    self.endpoint = '/subscriptions/:id'

    attr_accessor  :amount,
                   :currency,
                   :interval_length,
                   :interval_unit,
                   :name,
                   :description,
                   :plan_id,
                   :status,
                   :setup_fee,
                   :trial_length,
                   :trial_unit

    reference_accessor :merchant_id, :user_id

    date_accessor :start_at, :expires_at, :created_at, :next_interval_start

    has_statuses :inactive, :active, :cancelled, :expired

    def cancel!
      path = self.class.endpoint.gsub(':id', id.to_s) + '/cancel'
      client.api_put(path)
    end

  end
end

