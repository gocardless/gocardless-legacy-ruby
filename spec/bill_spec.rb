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
end
