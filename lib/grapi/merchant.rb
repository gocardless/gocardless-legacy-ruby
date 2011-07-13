require 'date'

module Grapi
  class Merchant < Resource
    attr_accessor :name, :uri, :id, :description, :email, :first_name,
                  :last_name
    attr_reader :created_at

    def created_at=(date)
      @created_at = date.is_a?(String) ? DateTime.parse(date) : date
    end

  end
end
