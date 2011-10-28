
class String
  def camelize
    self.split('_').map(&:capitalize).join
  end

  def underscore
    self.gsub(/(.)([A-Z])/) { "#{$1}_#{$2.downcase}" }.downcase
  end

  def singularize
    # This should probably be a bit more robust
    self.sub(/s$/, '').sub(/i$/, 'us')
  end
end


class Hash
  def symbolize_keys
    dup.symbolize_keys!
  end

  def symbolize_keys!
    self.keys.each do |key|
      sym_key = key.to_s.to_sym rescue key
      self[sym_key] = self.delete(key) unless self.key?(sym_key)
    end
    self
  end
end

