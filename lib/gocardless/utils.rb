
module GoCardless
  module Utils
    class << self

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

    end
  end
end

