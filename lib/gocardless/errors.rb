require 'multi_json'

module GoCardless
  class Error < StandardError
  end

  class ApiError < Error
    attr_reader :response, :code, :description

    def initialize(response)
      @response = response
      @code = response.status
      body = MultiJson.decode(response.body) rescue nil
      if body.is_a? Hash
        @description = body["error"] || response.body.strip || "Unknown error"
      end
    end

    def to_s
      "#{super} [#{self.code}] #{self.description}"
    end
  end

  class ClientError < Error
  end

  class SignatureError < Error
  end
end
