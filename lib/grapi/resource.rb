require 'date'

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

    def self.find(client, id)
      path = self::ENDPOINT.gsub(':id', id.to_s)
      data = client.api_get(path)
      self.from_hash(client, data)
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

    attr_accessor :id, :uri
  end
end
