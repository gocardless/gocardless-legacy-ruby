require 'spec_helper'

describe GoCardless::PreAuthorization do
  before do
    GoCardless.account_details = {:app_id => 'abc', :app_secret => 'xyz',
                                  :token  => 'xxx', :merchant_id => '123'}
  end
  let(:client) { GoCardless.client }
  let(:preauth) { GoCardless::PreAuthorization.new(:id => '009988') }

  it "should be cancellable" do
    expect(client).to receive(:api_put).with('/pre_authorizations/009988/cancel')
    preauth.cancel!
  end

  it "should allow you to create a pre-authorised bill" do
    mocked_data = {
      :pre_authorization_id=>"009988",
      :amount=>"15.00",
      :name=>"150 credits",
      :charge_customer_at=>DateTime.new(2013,8,27,0,0,0,'0')
    }

    expect(client).to receive(:api_post).with('/bills/', :bill => mocked_data)
    preauth.create_bill(mocked_data)
  end

  it_behaves_like "it has a query method for", "inactive"
  it_behaves_like "it has a query method for", "active"
  it_behaves_like "it has a query method for", "cancelled"
  it_behaves_like "it has a query method for", "expired"
end
