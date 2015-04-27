require 'spec_helper'

describe GoCardless::ApiError do
  let(:response) { double(body: body, status: 500) }
  let(:error) { GoCardless::ApiError.new(response) }

  describe "#description" do
    subject { error.description }

    context "given no response body" do
      let(:body) { nil }
      it { is_expected.to eq "Unknown error" }
    end

    context "given a json response body with an 'errors' hash" do
      let(:body) do
        MultiJson.dump(errors: { name: ["too short"], email: ["taken", "invalid"] })
      end
      it { is_expected.to eq "name too short, email taken, email invalid" }
    end

    context "given a json response body with an 'error' array" do
      let(:body) { MultiJson.dump(error: ["Server Error", "Oops"]) }
      it { is_expected.to eq "Server Error, Oops" }
    end

    context "with a non-JSON body" do
      let(:body) { "non-json body" }
      it { is_expected.to eq "non-json body" }
    end
  end
end
