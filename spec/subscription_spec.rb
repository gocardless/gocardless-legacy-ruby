require 'spec_helper'

describe GoCardless::Subscription do
  before do
    GoCardless.account_details = {:app_id => 'abc', :app_secret => 'xyz',
                                  :token  => 'xxx', :merchant_id => '123'}
  end
  let(:client) { GoCardless.client }
  let(:subscription) { GoCardless::Subscription.new(:id => '009988') }

  it "should be cancellable" do
    expect(client).to receive(:api_put).with('/subscriptions/009988/cancel')
    subscription.cancel!
  end

  it_behaves_like "it has a query method for", "inactive"
  it_behaves_like "it has a query method for", "active"
  it_behaves_like "it has a query method for", "cancelled"
  it_behaves_like "it has a query method for", "expired"
end
