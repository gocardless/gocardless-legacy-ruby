require 'mocha'
require 'grapi'

RSpec.configure do |config|
  config.mock_with :mocha
end

def stub_get(client, data)
  response = mock
  response.stubs(:parsed).returns(data)

  token = client.instance_variable_get(:@access_token)
  token.stubs(:get).returns response
end

class String
  def camelize
    self.split('_').map {|w| w.capitalize}.join
  end
end

