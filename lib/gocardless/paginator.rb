require 'multi_json'
require 'gocardless/page'

module GoCardless
  class Paginator
    include Enumerable

    attr_reader :num_records
    attr_reader :num_pages

    DEFAULT_PAGE_NUMBER = 1
    DEFAULT_PAGE_SIZE   = 30

    def initialize(client, resource_class, path, query)
      @client = client
      @resource_class = resource_class
      @path, @query = path, query
      @page_number, @per_page = DEFAULT_PAGE_NUMBER, DEFAULT_PAGE_SIZE
    end

    # Set the number of records per page (page size), if an argument is
    # provided. Returns the current per_page value, whether an argument is
    # provided or not.
    def per_page(n = nil)
      unless n.nil?
        @num_records, @num_pages = nil, nil
        @per_page = n
      end

      @per_page
    end

    # Fetch and return a single page.
    def load_page(page_num)
      params = @query.merge(pagination_params(page_num))
      response = @client.api_request(:get, @path, :params => params)

      metadata = parse_metadata(response)
      @num_records, @num_pages = metadata['records'], metadata['pages']

      Page.new(@resource_class, response.parsed, metadata['links'])
    end

    alias_method :page, :load_page

    # Yield every record from every current page, auto-fetching new pages as
    # the iteration happens. Records are returned as instances of the
    # appropriate resource classes (e.g. Subscription).
    def each(&block)
      each_page { |page| page.each(&block) }
    end

    # Fetch and yield each page of results.
    def each_page
      page_obj = load_page(1)
      loop do
        yield page_obj
        break unless page_obj.has_next?
        page_obj = load_page(page_obj.next_page)
      end
    end

    # Return the total number of records. May trigger an HTTP request.
    def count
      load_page(1) if @num_records.nil?  # load pagination metadata
      @num_records
    end

    # Return the total number of pages. May trigger an HTTP request.
    def page_count
      load_page(1) if @num_records.nil?  # load pagination metadata
      @num_pages
    end

    private

    def pagination_params(page_num)
      { :page => page_num, :per_page => @per_page }
    end

    def parse_metadata(response)
      MultiJson.load(response.headers['X-Pagination'])
    end
  end
end
