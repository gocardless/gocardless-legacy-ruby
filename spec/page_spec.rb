require 'spec_helper'
require 'gocardless/page'

describe GoCardless::Page do
  #let(:resource_class) { Class.new(GoCardless::Resource) { } }
  let(:resource_class) { GoCardless::Resource }
  let(:links) {{ "next" => 2, "last" => 2 }}
  let(:data) {[ { :id => 'a' }, { :id => 'b' } ]}

  let(:page) { GoCardless::Page.new(resource_class, data, links) }

  describe "#has_next?" do
    subject { page.has_next? }

    context "when there is next page available" do
      let(:links) {{ "next" => 2, "last" => 2 }}
      it { is_expected.to be_truthy }
    end

    context "when there is no next page" do
      let(:links) {{ "previous" => 1, "first" => 1 }}
      it { is_expected.to be_falsey }
    end
  end

  describe "#next_page" do
    subject { page.next_page }

    context "when there is next page available" do
      let(:links) {{ "next" => 2, "last" => 2 }}
      it { is_expected.to eq(2) }
    end

    context "when there is no next page" do
      let(:links) {{ "previous" => 1, "first" => 1 }}
      it { is_expected.to be_nil }
    end
  end

  describe "#previous_page" do
    subject { page.previous_page }

    context "when there is previous page available" do
      let(:links) {{ "previous" => 1, "first" => 1 }}
      it { is_expected.to eq(1) }
    end

    context "when there is no previous page" do
      let(:links) {{ "next" => 2, "last" => 2 }}
      it { is_expected.to be_nil }
    end
  end

  describe "#first_page" do
    subject { page.first_page }

    context "when there is first page available" do
      let(:links) {{ "first" => 1, "previous" => 1 }}
      it { is_expected.to eq(1) }
    end

    context "when there is no first page" do
      let(:links) {{ "next" => 2, "last" => 2 }}
      it { is_expected.to be_nil }
    end
  end

  describe "#last_page" do
    subject { page.last_page }

    context "when there is last page available" do
      let(:links) {{ "next" => 2, "last" => 2 }}
      it { is_expected.to eq(2) }
    end

    context "when there is no last page" do
      let(:links) {{ "previous" => 1, "first" => 1 }}
      it { is_expected.to be_nil }
    end
  end

  describe "#each" do
    it "yields resource instances for each data item" do
      resources = [a_kind_of(resource_class), a_kind_of(resource_class)]
      expect { |b| page.each(&b) }.to yield_successive_args(*resources)
    end

    it "properly initialises the resources" do
      expect(page.map(&:id)).to eq(['a', 'b'])
    end
  end
end

