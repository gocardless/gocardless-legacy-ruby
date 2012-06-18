module GoCardless
  class PreAuthorization < Resource
    self.endpoint = '/pre_authorizations/:id'

    attr_accessor :max_amount,
                  :currency,
                  :amount,
                  :interval_length,
                  :interval_unit,
                  :name,
                  :description,
                  :plan_id,
                  :status

    reference_accessor :merchant_id, :user_id
    date_accessor :expires_at, :created_at

    # Create a new bill under this pre-authorization. Similar to
    # {Client#create_bill}, but only requires the amount to be specified.
    #
    # @option attrs [amount] amount the bill amount in pence
    # @return [Bill] the created bill object
    def create_bill(attrs)
      Bill.new_with_client(client, attrs.merge(:source => self)).save
    end
  end
end

