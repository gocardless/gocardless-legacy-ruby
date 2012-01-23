require 'spec_helper'

describe GoCardless do
  before do
    unset_ivar GoCardless, :client
    unset_ivar GoCardless, :account_details
    @details = {:app_id => 'X', :app_secret => 'X', :token => 'X manage_merchant:1'}
  end

  describe ".account_details=" do
    it "creates a Client instance" do
      GoCardless::Client.expects :new
      subject.account_details = @details
    end

    it "gets upset if the token is missing" do
      expect {
        subject.account_details = @details.merge(:token => nil)
      }.to raise_exception GoCardless::ClientError
    end
  end


  describe "delegated methods" do
    %w(new_subscription_url new_pre_authorization_url new_bill_url confirm_resource webhook_valid?).each do |name|
      it "#{name} delegates to @client" do
        subject.account_details = @details
        subject.instance_variable_get(:@client).expects(name.to_sym)
        subject.send(name)
      end

      it "raises an exception if the account details aren't set" do
        expect {
          subject.send(name)
        }.to raise_exception GoCardless::ClientError
      end
    end
  end

end

