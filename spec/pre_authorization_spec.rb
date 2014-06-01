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

  it_behaves_like "it has a query method for", "inactive"
  it_behaves_like "it has a query method for", "active"
  it_behaves_like "it has a query method for", "cancelled"
  it_behaves_like "it has a query method for", "expired"
end
