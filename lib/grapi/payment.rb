module Grapi
  class Payment < Resource
    ENDPOINT = '/payments/:id'

    attr_accessor :amount, :currency, :merchant_id, :user_id, :status
    date_accessor :created_at
  end
end
