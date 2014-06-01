require 'spec_helper'

describe GoCardless::Bill do
  before :each do
    @app_id = 'abc'
    @app_secret = 'xyz'
    GoCardless.account_details = {:app_id => @app_id, :app_secret => @app_secret,
                                  :token  => 'xxx', :merchant_id => '1'}
    @client = GoCardless.client
  end

  it "source getter works" do
    b = GoCardless::Bill.new(:source_type => :subscription, :source_id => 123)
    @client.access_token = 'TOKEN'
    @client.merchant_id = '123'
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

  it "should be able to be retried" do
    b = GoCardless::Bill.new(:id => 123)
    @client.should_receive(:api_post).with('/bills/123/retry')
    b.retry!
  end

  it "should be able to be cancelled" do
    b = GoCardless::Bill.new(:id => 123)
    @client.should_receive(:api_put).with('/bills/123/cancel')
    b.cancel!
  end

  it "should be able to be refunded" do
    b = GoCardless::Bill.new(:id => 123)
    @client.should_receive(:api_post).with('/bills/123/refund')
    b.refund!
  end

  it_behaves_like "it has a query method for", "pending"
  it_behaves_like "it has a query method for", "paid"
  it_behaves_like "it has a query method for", "failed"
  it_behaves_like "it has a query method for", "withdrawn"
  it_behaves_like "it has a query method for", "refunded"
end
