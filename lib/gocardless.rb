module GoCardless
  require 'gocardless/version'
  require 'gocardless/errors'
  require 'gocardless/utils'
  require 'gocardless/resource'
  require 'gocardless/subscription'
  require 'gocardless/pre_authorization'
  require 'gocardless/user'
  require 'gocardless/bill'
  require 'gocardless/merchant'
  require 'gocardless/client'
  require 'gocardless/payout'

  class << self
    attr_reader :account_details, :environment, :client

    def account_details=(details)
      raise ClientError.new("You must provide a token") unless details[:token]
      @account_details = details
      @client = Client.new(details)
    end

    def environment=(gc_env)
      valid_environments = GoCardless::Client::BASE_URLS.keys
      if !gc_env.nil? && !valid_environments.include?(gc_env)
        raise ClientError.new("The GoCardless environment must be one of " +
                              valid_environments.join(", "))
      end

      @environment = gc_env
    end

    %w(new_subscription_url new_pre_authorization_url new_bill_url confirm_resource webhook_valid?).each do |name|
      class_eval <<-EOM
        def #{name}(*args)
          raise ClientError.new('Need to set account_details first') unless @client
          @client.send(:#{name}, *args)
        end
      EOM
    end
  end
end
