module GoCardless
  class Bill < Resource
    self.endpoint = '/bills/:id'

    creatable

    attr_accessor :amount,
                  :source_type,
                  :description,
                  :name,
                  :plan_id

    # @attribute source_id
    # @return [String] the ID of the bill's source (eg subscription, pre_authorization)
    attr_accessor :source_id

    reference_accessor :merchant_id, :user_id, :payment_id
    date_accessor :created_at

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

    def save
      save_data({
        :bill => {
          :pre_authorization_id => self.source_id,
          :amount => self.amount,
          :name => self.name,
          :description => self.description,
        }
      })
      self
    end
  end
end
