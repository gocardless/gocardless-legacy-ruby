module Grapi
  class Subscription < Resource

    self.endpoint = '/subscriptions/:id'

    attr_accessor  :amount, :currency, :frequency_length, :frequency_unit,
                   :description, :setup_fee, :trial_length, :trial_unit

    reference_accessor :merchant_id, :user_id

    date_accessor :expires_at, :created_at

  end
end

