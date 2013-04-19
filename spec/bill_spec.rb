require 'spec_helper'

describe GoCardless::Bill do
  before :each do
    @app_id = 'abc'
    @app_secret = 'xyz'
    GoCardless.account_details = {:app_id => @app_id, :app_secret => @app_secret,
                                  :token  => 'xxx manage_merchant:1'}
    @client = GoCardless.client
  end

  it "source getter works" do
    b = GoCardless::Bill.new(:source_type => :subscription, :source_id => 123)
    @client.access_token = 'TOKEN manage_merchant:123'
    stub_get(@client, :id => 123)
    source = b.source
    source.should be_a GoCardless::Subscription
    source.id.should == 123
  end

  it "source setter works" do
    b = GoCardless::Bill.new
    b.source = GoCardless::Subscription.new(:id => 123)
    b.source_id.should == 123
    b.source_type.should.to_s == 'subscription'
  end

  describe "pending query method" do
    it "returns true when the subscription status is pending" do
      GoCardless::Bill.new(:status => 'pending').pending?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Bill.new.pending?.should be_false
    end
  end

  describe "paid query method" do
    it "returns true when the subscription status is paid" do
      GoCardless::Bill.new(:status => 'paid').paid?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Bill.new.paid?.should be_false
    end
  end

  describe "failed query method" do
    it "returns true when the subscription status is failed" do
      GoCardless::Bill.new(:status => 'failed').failed?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Bill.new.failed?.should be_false
    end
  end

  describe "withdrawn query method" do
    it "returns true when the subscription status is withdrawn" do
      GoCardless::Bill.new(:status => 'withdrawn').withdrawn?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Bill.new.withdrawn?.should be_false
    end
  end

  describe "refunded query method" do
    it "returns true when the subscription status is refunded" do
      GoCardless::Bill.new(:status => 'refunded').refunded?.should be_true
    end

    it "returns false otherwise" do
      GoCardless::Bill.new.refunded?.should be_false
    end
  end
end
