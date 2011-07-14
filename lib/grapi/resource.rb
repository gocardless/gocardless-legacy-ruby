
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

    def self.date_writer(*args)
      args.each do |attr|
        define_method("#{attr.to_s}=".to_sym) do |date|
          date = date.is_a?(String) ? DateTime.parse(date) : date
          instance_variable_set("@#{attr}", date)
        end
      end
    end

    def self.date_accessor(*args)
      attr_reader *args
      date_writer *args
    end
  end
end
