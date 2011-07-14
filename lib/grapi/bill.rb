module Grapi
  class Bill < Resource
    ENDPOINT = '/bills/:id'

    attr_accessor :amount, :merchant_id, :user_id, :payment_id, :source, :source_id
    date_accessor :created_at
  end
end
