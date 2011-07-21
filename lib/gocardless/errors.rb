require 'rubygems'
require 'json'

module GoCardless
  class ApiError < StandardError
    attr_reader :response, :code, :description

    def initialize(response)
      @response = response
      @code = response.status
      body = JSON.parse(response.body) rescue nil
      if body.is_a? Hash
        @description = body["error"] || "Unknown error"
      end
    end

    def to_s
      "#{super} [#{self.code}] #{self.description}"
    end
  end
end
