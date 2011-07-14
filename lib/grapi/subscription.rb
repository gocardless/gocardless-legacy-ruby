module Grapi
  class Subscription < Resource

    attr_accessor  :amount, :currency, :frequency_length, :frequency_unit,
                   :description, :setup_fee, :trial_length, :trial_unit,
                   :merchant_id, :user_id

    date_accessor :expires_at, :created_at

  end
end

