module GoCardless
  class Bill < Resource
    self.endpoint = '/bills/:id'

    creatable

    attr_accessor :amount,
                  :currency,
                  :description,
                  :name,
                  :status,
                  :gocardless_fees,
                  :partner_fees,
                  :amount_minus_fees,
                  :can_be_retried,
                  :can_be_cancelled,
                  :is_setup_fee

    # @attribute source_id
    # @return [String] the ID of the bill's source (eg subscription, pre_authorization)
    attr_accessor :source_id
    attr_accessor :source_type

    reference_accessor :merchant_id, :user_id, :payout_id
    date_accessor :created_at, :paid_at, :charge_customer_at

    # Alias getter methods
    alias_method :is_setup_fee?, :is_setup_fee
    alias_method :can_be_cancelled?, :can_be_cancelled
    alias_method :can_be_retried?, :can_be_retried

    def source
      klass = GoCardless.const_get(Utils.camelize(source_type.to_s))
      klass.find_with_client(client, @source_id)
    end

    def source=(obj)
      klass = obj.class.to_s.split(':').last
      if !%w{Subscription PreAuthorization}.include?(klass)
        raise ArgumentError, ("Object must be an instance of Subscription or "
                              "PreAuthorization")
      end
      @source_id = obj.id
      @source_type = Utils.underscore(klass)
    end

    def retry!
      path = self.class.endpoint.gsub(':id', id.to_s) + '/retry'
      client.api_post(path)
    end

    def cancel!
      path = self.class.endpoint.gsub(':id', id.to_s) + '/cancel'
      client.api_put(path)
    end

    # The ability to refund a payment is disabled by default.
    #
    # Please contact help@gocardless.com if you require access to
    # the refunds API endpoint.
    def refund!
      path = self.class.endpoint.gsub(':id', id.to_s) + '/refund'
      client.api_post(path)
    end

    def save
      bill_params = {
        :pre_authorization_id => self.source_id,
        :amount => self.amount,
        :name => self.name,
        :description => self.description,
        :charge_customer_at => self.charge_customer_at,
      }

      bill_params.delete_if { |_,v| v.nil? }

      save_data({ :bill => bill_params })
      self
    end

    def pending?
      status == 'pending'
    end

    def paid?
      status == 'paid'
    end

    def failed?
      status == 'failed'
    end

    def withdrawn?
      status == 'withdrawn'
    end

    def refunded?
      status == 'refunded'
    end
  end
end
