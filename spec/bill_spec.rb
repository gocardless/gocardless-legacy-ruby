require 'spec_helper'

describe GoCardless::Bill do
  before do
    GoCardless.account_details = {:app_id => 'abc', :app_secret => 'xyz',
                                  :token  => 'xxx', :merchant_id => '123'}
  end
  let(:client) { GoCardless.client }
  let(:bill) { GoCardless::Bill.new(:id => 123) }

  it "source getter works" do
    bill.source_id = 123
    bill.source_type = :subscription
    stub_get(client, :id => 123)
    source = bill.source
    expect(source).to be_a GoCardless::Subscription
    expect(source.id).to eq(123)
  end

  it "source setter works" do
    bill.source = GoCardless::Subscription.new(:id => 123)
    expect(bill.source_id).to eq(123)
    expect(bill.source_type.to_s).to eq('subscription')
  end

  it "should be able to be retried" do
    expect(client).to receive(:api_post).with('/bills/123/retry')
    bill.retry!
  end

  it "should be able to be cancelled" do
    expect(client).to receive(:api_put).with('/bills/123/cancel')
    bill.cancel!
  end

  it "should be able to be refunded" do
    expect(client).to receive(:api_post).with('/bills/123/refund')
    bill.refund!
  end

  it_behaves_like "it has a query method for", "pending"
  it_behaves_like "it has a query method for", "paid"
  it_behaves_like "it has a query method for", "failed"
  it_behaves_like "it has a query method for", "withdrawn"
  it_behaves_like "it has a query method for", "refunded"
end
