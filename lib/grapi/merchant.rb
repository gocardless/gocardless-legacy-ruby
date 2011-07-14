require 'date'

module Grapi
  class Merchant < Resource
    attr_accessor :name, :uri, :id, :description, :email, :first_name,
                  :last_name
    date_accessor :created_at
  end
end
