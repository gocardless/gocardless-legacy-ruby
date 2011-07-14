require 'spec_helper'

describe Grapi::Merchant do
  before :each do
    @app_id = 'abc'
    @app_secret = 'xyz'
    @client = Grapi::Client.new(@app_id, @app_secret)
    @client.access_token = 'TOKEN123 manage_merchant:123'
    @redirect_uri = 'http://test.com/cb'
  end

  it "#subscriptions works correctly" do
    merchant = Grapi::Merchant.new(@client)

    subscription_data = [{:id => 1}, {:id => 2}]
    stub_get(@client, subscription_data)

    merchant.subscriptions.should be_a Array
    merchant.subscriptions.length.should == 2
    merchant.subscriptions.zip(subscription_data).each do |subscription,attrs|
      subscription.should be_a Grapi::Subscription
      attrs.each { |k,v| subscription.send(k).should == v }
    end
  end
end

