require 'spec_helper'
require 'gocardless/paginator'

describe GoCardless::Paginator do
  let(:resource_class) { GoCardless::Resource }
  let(:path) { '/test' }
  let(:query) { { status: 'active' } }
  let(:per_page) { 10 }
  let(:page_number) { 1 }

  let(:headers_p1) {{
    'X-Pagination' => '{"records":15,"pages":2,"links":{"next":2,"last":2}}'
  }}
  let(:response_p1) { stub(headers: headers_p1, parsed: [{ id: 'a' }]) }

  let(:headers_p2) {{
    'X-Pagination' => '{"records":15,"pages":2,"links":{"previous":1,"first":1}}'
  }}
  let(:response_p2) { stub(headers: headers_p2, parsed: [{ id: 'b' }]) }

  let(:client) { stub('client') }
  before { client.stub(:api_request).and_return(response_p1, response_p2) }

  let(:paginator) do
    GoCardless::Paginator.new(client, resource_class, path, query, page_number,
                              per_page)
  end

  describe "#load_page" do
    it "asks the client for the correct path" do
      client.should_receive(:api_request).
             with(:get, '/test', anything).
             and_return(response_p1)
      paginator  # implicitly calls #load_page in the constructor
    end

    it "passes the correct pagination parameters through" do
      pagination_params = { page: page_number, per_page: per_page }
      client.should_receive(:api_request) do |_, _, opts|
        opts[:params].should include pagination_params
      end.and_return(response_p1)
      paginator  # implicitly calls #load_page in the constructor
    end

    it "sets num_records" do
      paginator.num_records.should == 15
    end

    it "sets num_pages" do
      paginator.num_pages.should == 2
    end

    it "sets #page a Page object" do
      paginator.page.should be_a GoCardless::Page
      paginator.page.next_page.should == 2
    end
  end

  describe "#each" do
    it "yields items from the current page" do
      resource = a_kind_of(resource_class)
      expect { |b| paginator.each(&b) }.to yield_with_args(resource)
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
end

