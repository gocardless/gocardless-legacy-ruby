
class String
  def camelize
    self.split('_').map(&:capitalize).join
  end
end

