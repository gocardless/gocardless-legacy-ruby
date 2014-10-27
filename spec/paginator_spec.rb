require 'spec_helper'
require 'gocardless/paginator'

describe GoCardless::Paginator do
  let(:resource_class) { GoCardless::Resource }
  let(:path) { '/test' }
  let(:query) { { :status => 'active' } }
  let(:per_page) { 10 }
  let(:page_number) { 1 }

  let(:headers_p1) {{
    'X-Pagination' => '{"records":15,"pages":2,"links":{"next":2,"last":2}}'
  }}
  let(:response_p1) { double(:headers => headers_p1, :parsed => [{:id => 'a'}]) }

  let(:headers_p2) {{
    'X-Pagination' => '{"records":15,"pages":2,"links":{"previous":1,"first":1}}'
  }}
  let(:response_p2) { double(:headers => headers_p2, :parsed => [{:id => 'b'}]) }

  let(:client) { double('client') }
  before { allow(client).to receive(:api_request).and_return(response_p1, response_p2,
                                                response_p1, response_p2) }

  let(:paginator) { described_class.new(client, resource_class, path, query) }
  before { paginator.per_page(per_page) }

  describe "#per_page" do
    context "given no arguments" do
      subject { paginator.per_page }
      it { is_expected.to eq(per_page) }
    end

    context "given an argument" do
      it "is chainable" do
        expect(paginator.per_page(60)).to eq(paginator)
      end
    end

    it "resets pagination metadata" do
      expect(paginator).to receive(:load_page).exactly(2).times
      paginator.count  # reset metadata, check that we have to reload it
      paginator.per_page(50)
      paginator.count
    end
  end

  describe "#load_page" do
    it "asks the client for the correct path" do
      expect(client).to receive(:api_request).
             with(:get, '/test', anything).
             and_return(response_p1)
      paginator.page(page_number)
    end

    it "passes the correct pagination parameters through" do
      pagination_params = { :page => page_number, :per_page => per_page }
      expect(client).to receive(:api_request) { |_, _, opts|
        expect(opts[:params]).to include pagination_params
      }.and_return(response_p1)
      paginator.page(page_number)
    end
  end

  describe "#each" do
    it "yields every item from each page" do
      resources = [a_kind_of(resource_class), a_kind_of(resource_class)]
      expect { |b| paginator.each(&b) }.to yield_successive_args(*resources)
    end
  end

  describe "#each_page" do
    let(:pages) { [a_kind_of(GoCardless::Page), a_kind_of(GoCardless::Page)] }

    it "yields each page until there are none left" do
      expect { |b| paginator.each_page(&b) }.to yield_successive_args(*pages)
    end

    it "can be iterated over multiple times" do
      2.times do
        expect { |b| paginator.each_page(&b) }.to yield_successive_args(*pages)
      end
    end
  end

  describe "#count" do
    subject { paginator.count }

    context "when metadata is loaded" do
      before { paginator.page(1) }

      it { is_expected.to eq(15) }

      it "doesn't reload metadata" do
        expect(paginator).not_to receive(:load_page)
        paginator.count
      end
    end

    context "when metadata is not loaded" do
      it { is_expected.to eq(15) }

      it "loads metadata" do
        expect(paginator).to receive(:load_page)
        paginator.count
      end
    end
  end

  describe "#page_count" do
    subject { paginator.page_count }

    context "when metadata is loaded" do
      before { paginator.page(1) }

      it { is_expected.to eq(2) }

      it "doesn't reload metadata" do
        expect(paginator).not_to receive(:load_page)
        paginator.page_count
      end
    end

    context "when metadata is not loaded" do
      it { is_expected.to eq(2) }

      it "loads metadata" do
        expect(paginator).to receive(:load_page)
        paginator.page_count
      end
    end
  end
end

