
class String
  def camelize
    self.split('_').map {|w| w.capitalize}.join
  end
end

