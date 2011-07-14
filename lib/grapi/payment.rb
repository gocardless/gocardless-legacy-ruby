module Grapi
  class Payment < Resource
    attr_accessor :amount, :currency, :merchant_id, :user_id, :status
    date_accessor :created_at
  end
end
