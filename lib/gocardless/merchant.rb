module GoCardless
  class Merchant < Resource
    self.endpoint = '/merchants/:id'

    attr_accessor :name,
                  :description,
                  :email,
                  :first_name,
                  :last_name,
                  :balance,
                  :pending_balance,
                  :next_payout_amount,
                  :hide_variable_amount
    date_accessor :created_at, :next_payout_date
  end
end
