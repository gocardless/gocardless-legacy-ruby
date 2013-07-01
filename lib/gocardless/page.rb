module GoCardless
  class Page
    include Enumerable

    def initialize(resource_class, data, links)
      @resource_class = resource_class
      @data = data
      @links = links
    end

    # The next page number, nil if there is no next page
    def next_page
      @links['next']
    end

    # The previous page number, nil if there is no previous page
    def previous_page
      @links['previous']
    end

    # The first page number, nil if this is the first page
    def first_page
      @links['first']
    end

    # The last page number, nil if this is the last page
    def last_page
      @links['last']
    end

    # Used for page iteration
    def has_next?
      !!@links['next']
    end

    # Yield each of the items in the page as instances of the resource class
    def each(&block)
      @data.each do |attrs|
        yield @resource_class.new(attrs)
      end
    end
  end
end
