require 'spec_helper'

describe GoCardless do
  before do
    unset_ivar GoCardless, :client
    unset_ivar GoCardless, :account_details
    @details = { :app_id => 'X', :app_secret => 'X',
                 :token => 'X', :merchant_id => '1' }
  end

  describe ".account_details=" do
    it "creates a Client instance" do
      expect(GoCardless::Client).to receive :new
      subject.account_details = @details
    end

    it "gets upset if the token is missing" do
      expect {
        subject.account_details = @details.merge(:token => nil)
      }.to raise_exception GoCardless::ClientError
    end
  end

  describe ".environment=" do
    subject(:method) { -> { GoCardless.environment = gc_env } }

    context "with a valid environment" do
      let(:gc_env) { :production }
      it { is_expected.to_not raise_error }
      it 'sets the environment' do
        method.call
        expect(GoCardless.environment).to eq(gc_env)
      end
    end

    context "with an invalid environment" do
      let(:gc_env) { :foobar }
      it { is_expected.to raise_error }
    end
  end


  describe "delegated methods" do
    %w(new_subscription_url new_pre_authorization_url new_bill_url confirm_resource webhook_valid?).each do |name|
      it "#{name} delegates to @client" do
        subject.account_details = @details
        expect(subject.instance_variable_get(:@client)).to receive(name.to_sym)
        subject.send(name)
      end

      it "raises an exception if the account details aren't set" do
        expect {
          subject.send(name)
        }.to raise_exception GoCardless::ClientError
      end
    end
  end

end

