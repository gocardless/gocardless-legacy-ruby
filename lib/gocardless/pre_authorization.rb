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
                  :status,
                  :remaining_amount

    reference_accessor :merchant_id, :user_id

    date_accessor :expires_at, :created_at, :next_interval_start

    # Create a new bill under this pre-authorization. Similar to
    # {Client#create_bill}, but only requires the amount to be specified.
    #
    # @option attrs [amount] amount the bill amount in pence
    # @return [Bill] the created bill object
    def create_bill(attrs)
      Bill.new_with_client(client, attrs.merge(:source => self)).save
    end

    def cancel!
      path = self.class.endpoint.gsub(':id', id.to_s) + '/cancel'
      client.api_put(path)
    end

    def inactive?
      status == 'inactive'
    end

    def active?
      status == 'active'
    end

    def cancelled?
      status == 'cancelled'
    end

    def expired?
      status == 'expired'
    end

  end
end

