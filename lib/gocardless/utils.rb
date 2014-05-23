require 'uri'

module GoCardless
  module Utils
    extend self

    # String Helpers
    def camelize(str)
      str.split('_').map(&:capitalize).join
    end

    def underscore(str)
      str.gsub(/(.)([A-Z])/) { "#{$1}_#{$2.downcase}" }.downcase
    end

    def singularize(str)
      # This should probably be a bit more robust
      str.sub(/s$/, '').sub(/i$/, 'us')
    end

    # Hash Helpers
    def symbolize_keys(hash)
      symbolize_keys! hash.dup
    end

    def symbolize_keys!(hash)
      hash.keys.each do |key|
        sym_key = key.to_s.to_sym rescue key
        hash[sym_key] = hash.delete(key) unless hash.key?(sym_key)
      end
      hash
    end

    # Percent encode a string according to RFC 5849 (section 3.6)
    #
    # @param [String] str the string to encode
    # @return [String] str the encoded string
    def percent_encode(str)
      URI.encode(str, /[^a-zA-Z0-9\-\.\_\~]/)
    end

    # Flatten a hash containing nested hashes and arrays to a non-nested array
    # of key-value pairs.
    #
    # Examples:
    #
    #   flatten_params(a: 'b')
    #   # => [['a', 'b']]
    #
    #   flatten_params(a: ['b', 'c'])
    #   # => [['a[]', 'b'], ['a[]', 'c']]
    #
    #   flatten_params(a: {b: 'c'})
    #   # => [['a[b]', 'c']]
    #
    # @param [Hash] obj the hash to flatten
    # @return [Array] an array of key-value pairs (arrays of two strings)
    def flatten_params(obj, ns=nil)
      case obj
      when Hash
        pairs = obj.map { |k,v| flatten_params(v, ns ? "#{ns}[#{k}]" : k) }
        pairs.empty? ? [] : pairs.inject(&:+)
      when Array
        obj.map { |v| flatten_params(v, "#{ns}[]") }.inject(&:+) || []
      when Time
        [[ns.to_s, iso_format_time(obj)]]
      else
        [[ns.to_s, obj.to_s]]
      end
    end

    # Generate a percent-encoded query string from an object. The object may
    # have nested arrays and objects as values. Ordinary top-level key-value
    # pairs will be of the form "name=Bob", arrays will result in
    # "cars[]=BMW&cars[]=Fiat", and nested objects will look like
    # "user[name]=Bob&user[age]=50". All keys and values will be
    # percent-encoded according to RFC5849 §3.6 and parameters will be
    # normalised according to RFC5849 §3.4.1.3.2.
    def normalize_params(params)
      flatten_params(params).sort.map do |pair|
        pair.map { |item| percent_encode(item) } * '='
      end * '&'
    end

    # Given a Hash of parameters, normalize then (flatten and convert to a
    # string), then generate the HMAC-SHA-256 signature using the provided key.
    #
    # @param [Hash] params the parameters to sign
    # @param [String] key the key to sign the params with
    # @return [String] the resulting signature
    def sign_params(params, key)
      msg = Utils.normalize_params(params)
      digest = OpenSSL::Digest.new('sha256')
      OpenSSL::HMAC.hexdigest(digest, key, msg)
    end

    # Format a Time object according to ISO 8601, and convert to UTC.
    #
    # @param [Time] time the time object to format
    # @return [String] the ISO-formatted time
    def iso_format_time(time)
      return time unless time.is_a? Time or time.is_a? Date
      time = time.getutc if time.is_a? Time
      time = time.new_offset(0) if time.is_a? DateTime
      time.strftime('%Y-%m-%dT%H:%M:%SZ')
    end

    # Recursively ISO format all time and date values.
    #
    # @param [Hash] obj the object containing date or time objects
    # @return [Hash] the object with ISO-formatted time stings
    def stringify_times(obj)
      case obj
      when Hash
        Hash[obj.map { |k,v| [k, stringify_times(v)] }]
      when Array
        obj.map { |v| stringify_times(v) }
      else
        iso_format_time(obj)
      end
    end
  end
end

