module GoCardless
  class User < Resource
    self.endpoint = '/users/:id'

    attr_accessor :name, :first_name, :last_name, :email
    date_accessor :created_at

    def name
      "#{first_name}#{' ' + last_name unless last_name.blank?}"
    end
  end
end
