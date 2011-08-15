
class String
  def camelize
    self.split('_').map(&:capitalize).join
  end

  def underscore
    self.gsub(/(.)([A-Z])/) { "#{$1}_#{$2.downcase}" }.downcase
  end

  def singularize
    # This should probably be a bit more robust
    self.sub(/i$/, 'us').sub(/s$/, '')
  end
end

