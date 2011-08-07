
class String
  def camelize
    self.split('_').map(&:capitalize).join
  end

  def underscore
    self.gsub(/(.)([A-Z])/) { "#{$1}_#{$2.downcase}" }.downcase
  end
end

