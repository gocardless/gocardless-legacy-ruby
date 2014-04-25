module GoCardless
  class Payout < Resource
    self.endpoint = '/payouts/:id'

    attr_accessor :amount,
                  :bank_reference,
                  :transaction_fees

    date_accessor :created_at, :paid_at
  end
end
