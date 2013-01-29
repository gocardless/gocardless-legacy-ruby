module GoCardless
  class Merchant < Resource
    self.endpoint = '/merchants/:id'

    date_accessor :created_at, :next_payout_date
  end
end
