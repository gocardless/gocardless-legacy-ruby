require 'spec_helper'

describe GoCardless::User do
  let(:user) { GoCardless::User.new(:id => 123, :first_name => first, :last_name => last) }

  describe "#name" do
    subject { user.name }

    context "with first and last name" do
      let(:first) { "First" }
      let(:last) { "Last" }
      it { should == "First Last" }
    end

    context "with first name only" do
      let(:first) { "First" }
      let(:last) { nil }
      it { should == "First" }
    end

    context "with last name only" do
      let(:first) { nil }
      let(:last) { "Last" }
      it { should == "Last" }
    end

    context "with no first or last name" do
      let(:first) { nil }
      let(:last) { nil }
      it { should == "" }
    end
  end
end
