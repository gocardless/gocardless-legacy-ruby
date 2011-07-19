module Grapi
  class Payment < Resource
    self.endpoint = '/payments/:id'

    attr_accessor :amount, :currency, :status
    reference_accessor :merchant_id, :user_id
    date_accessor :created_at
  end
end
