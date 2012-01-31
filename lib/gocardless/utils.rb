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

    def percent_encode(str)
      URI.encode(str, /[^a-zA-Z0-9\-\.\_\~]/)
    end

    def flatten_params(obj, ns=nil)
      case obj
      when Hash
        obj.map { |k,v| flatten_params(v, ns ? "#{ns}[#{k}]" : k) }.inject(&:+)
      when Array
        obj.map { |v| flatten_params(v, "#{ns}[]") }.inject(&:+)
      else
        [[ns.to_s, obj.to_s]]
      end
    end

    def normalize_params(params)
      flatten_params(params).map do |pair|
        pair.map { |item| percent_encode(item) } * '='
      end.sort * '&'
    end
  end
end

