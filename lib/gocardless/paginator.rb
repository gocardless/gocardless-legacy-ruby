require 'multi_json'
require 'gocardless/page'

module GoCardless
  class Paginator
    attr_reader :num_records
    attr_reader :num_pages
    attr_reader :page

    def initialize(client, resource_class, path, query, page_number, per_page)
      @client = client
      @resource_class = resource_class
      @path, @query = path, query
      @page_number, @per_page = page_number, per_page

      @page = load_page(@page_number)
    end

    # Yield each record in the current page. Records are returned as instances
    # of the appropriate resource classes (e.g. Subscription).
    def each(&block)
      @page.each(&block)
    end

    # Fetch and yield each page of results, starting at the paginator's current
    # page. E.g., if there are 5 pages, and the paginator is initialised with
    # page 3, pages 3, 4, and 5 will be yielded.
    def each_page
      page = @page
      loop do
        yield page
        break unless page.has_next?
        page = load_page(page.next_page)
      end
    end

    private

    def load_page(page_num)
      params = @query.merge(pagination_params(page_num))
      response = @client.api_request(:get, @path, params: params)

      metadata = parse_metadata(response)
      @num_records, @num_pages = metadata['records'], metadata['pages']

      page = Page.new(@resource_class, response.parsed, metadata['links'])
    end

    def pagination_params(page_num)
      { page: page_num, per_page: @per_page }
    end

    def parse_metadata(response)
      MultiJson.load(response.headers['X-Pagination'])
    end
  end
end
