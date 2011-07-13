
module Grapi
  class Resource
    def self.from_hash(h)
      obj = self.new
      h.each { |k,v| obj.send("#{k}=", v) }
      obj
    end
  end
end
