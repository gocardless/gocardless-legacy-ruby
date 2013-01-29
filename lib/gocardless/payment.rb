module GoCardless
  class Payment < Resource
    self.endpoint = '/payments/:id'

    reference_accessor :merchant_id, :user_id
    date_accessor :created_at
  end
end
