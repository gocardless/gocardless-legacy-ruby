require 'spec_helper'

describe GoCardless::PreAuthorization do
  before do
    GoCardless.account_details = {:app_id => 'abc', :app_secret => 'xyz',
                                  :token  => 'xxx', :merchant_id => '123'}
  end
  let(:client) { GoCardless.client }
  let(:preauth) { GoCardless::PreAuthorization.new(:id => '009988') }

  it "should be cancellable" do
    client.should_receive(:api_put).with('/pre_authorizations/009988/cancel')
    preauth.cancel!
  end

  it_behaves_like "it has a query method for", "inactive"
  it_behaves_like "it has a query method for", "active"
  it_behaves_like "it has a query method for", "cancelled"
  it_behaves_like "it has a query method for", "expired"
end
