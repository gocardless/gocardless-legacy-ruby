require 'spec_helper'

describe GoCardless::PreAuthorization do
  before :each do
    @app_id = 'abc'
    @app_secret = 'xyz'
    GoCardless.account_details = {:app_id => @app_id, :app_secret => @app_secret,
                                  :token  => 'xxx', :merchant_id => '1'}
    @client = GoCardless.client
  end

  it "should be cancellable" do
    s = GoCardless::PreAuthorization.new_with_client(@client, :id => '009988')
    @client.should_receive(:api_put).with('/pre_authorizations/009988/cancel')
    s.cancel!
  end

  describe "inactive query method" do
    it "and_return true when the subscription status is inactive" do
      GoCardless::PreAuthorization.new(:status => 'inactive').inactive?.should be_true
    end

    it "and_return false otherwise" do
      GoCardless::PreAuthorization.new.inactive?.should be_false
    end
  end

  describe "active query method" do
    it "and_return true when the subscription status is active" do
      GoCardless::PreAuthorization.new(:status => 'active').active?.should be_true
    end

    it "and_return false otherwise" do
      GoCardless::PreAuthorization.new.active?.should be_false
    end
  end

  describe "cancelled query method" do
    it "and_return true when the subscription status is cancelled" do
      GoCardless::PreAuthorization.new(:status => 'cancelled').cancelled?.should be_true
    end

    it "and_return false otherwise" do
      GoCardless::PreAuthorization.new.cancelled?.should be_false
    end
  end

  describe "expired query method" do
    it "and_return true when the subscription status is expired" do
      GoCardless::PreAuthorization.new(:status => 'expired').expired?.should be_true
    end

    it "and_return false otherwise" do
      GoCardless::PreAuthorization.new.expired?.should be_false
    end
  end
end
