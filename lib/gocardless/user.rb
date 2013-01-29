module GoCardless
  class User < Resource
    self.endpoint = '/users/:id'

    date_accessor :created_at
  end
end
