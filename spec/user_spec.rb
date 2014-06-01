require 'spec_helper'

describe GoCardless::User do
  let(:user) { GoCardless::User.new(:first_name => first, :last_name => last) }

  describe "#name" do
    context "with first and last name" do
      let(:first) { "First" }
      let(:last) { "Last" }
      specify { user.name.should == "First Last" }
    end

    context "with first name only" do
      let(:first) { "First" }
      let(:last) { nil }
      specify { user.name.should == "First" }
    end

    context "with last name only" do
      let(:first) { nil }
      let(:last) { "Last" }
      specify { user.name.should == "Last" }
    end

    context "with no first or last name" do
      let(:first) { nil }
      let(:last) { nil }
      specify { user.name.should == "" }
    end
  end
end
