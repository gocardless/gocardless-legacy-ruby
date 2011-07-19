require 'mocha'
require 'json'
require 'gocardless'

RSpec.configure do |config|
  config.mock_with :mocha
end

def stub_get(client, data)
  response = mock
  response.stubs(:parsed).returns(data)

  token = client.instance_variable_get(:@access_token)
  token.stubs(:get).returns response
end

