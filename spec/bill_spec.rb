require 'spec_helper'

describe Grapi::Bill do
  before :each do
    @app_id = 'abc'
    @app_secret = 'xyz'
    @client = Grapi::Client.new(@app_id, @app_secret)
  end

  it "source getter works" do
    b = Grapi::Bill.from_hash(@client, :source_type => :subscription,
                                       :source_id => 123)
    stub_get(@client, :id => 123)
    source = b.source
    source.should be_a Grapi::Subscription
    source.id.should == 123
  end

  it "source setter works" do
    b = Grapi::Bill.new(@client)
    b.source = Grapi::Subscription.from_hash(@client, :id => 123)
    b.source_id.should == 123
    b.source_type.should.to_s == 'subscription'
  end
end
