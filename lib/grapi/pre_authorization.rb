module Grapi
  class PreAuthorization < Resource
    ENDPOINT = '/pre_authorizations/:id'

    attr_accessor :max_amount, :currency, :amount, :frequency_length,
                  :frequency_unit, :description, :merchant_id, :user_id

    date_accessor :expires_at, :created_at
  end
end

