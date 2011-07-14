
module Grapi
  class Resource

    def initialize(client)
      @client = client
    end

    def self.from_hash(client, hash)
      obj = self.new(client)
      hash.each { |key,val| obj.send("#{key}=", val) }
      obj
    end

  end
end
