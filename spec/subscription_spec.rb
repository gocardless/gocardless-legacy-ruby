require 'spec_helper'

describe GoCardless::Subscription do
  before :each do
    @app_id = 'abc'
    @app_secret = 'xyz'
    GoCardless.account_details = {:app_id => @app_id, :app_secret => @app_secret,
                                  :token  => 'xxx', :merchant_id => '1'}
    @client = GoCardless.client
  end

  it "should be cancellable" do
    s = GoCardless::Subscription.new_with_client(@client, :id => '009988')
    @client.expects(:api_put).with('/subscriptions/009988/cancel')
    s.cancel!
  end

  describe "inactive query method" do
    it "returns true when the subscription status is inactive" do
      GoCardless::Subscription.new(:status => 'inactive').inactive?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Subscription.new.inactive?.should be_false
    end
  end

  describe "active query method" do
    it "returns true when the subscription status is active" do
      GoCardless::Subscription.new(:status => 'active').active?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Subscription.new.active?.should be_false
    end
  end

  describe "cancelled query method" do
    it "returns true when the subscription status is cancelled" do
      GoCardless::Subscription.new(:status => 'cancelled').cancelled?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Subscription.new.cancelled?.should be_false
    end
  end

  describe "expired query method" do
    it "returns true when the subscription status is expired" do
      GoCardless::Subscription.new(:status => 'expired').expired?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Subscription.new.expired?.should be_false
    end
  end
end
