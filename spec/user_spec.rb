require 'spec_helper'

describe GoCardless::User do
  let(:user) { GoCardless::User.new(:id => 123, :first_name => "first", :last_name => "last") }

  describe "#name" do
    subject { user.name }
    it { should == "first last" }
  end
end