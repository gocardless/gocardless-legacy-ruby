require 'spec_helper'

describe GoCardless::User do
  let(:user) { GoCardless::User.new(:first_name => first, :last_name => last) }

  describe "#name" do
    context "with first and last name" do
      let(:first) { "First" }
      let(:last) { "Last" }
      specify { expect(user.name).to eq("First Last") }
    end

    context "with first name only" do
      let(:first) { "First" }
      let(:last) { nil }
      specify { expect(user.name).to eq("First") }
    end

    context "with last name only" do
      let(:first) { nil }
      let(:last) { "Last" }
      specify { expect(user.name).to eq("Last") }
    end

    context "with no first or last name" do
      let(:first) { nil }
      let(:last) { nil }
      specify { expect(user.name).to eq("") }
    end
  end
end
