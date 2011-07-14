module Grapi
  class AdHocAuthorization < Resource
    attr_accessor :amount, :currency, :description, :merchant_id, :user_id
    date_accessor :created_at
  end
end
