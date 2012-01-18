require 'mocha'
require 'json'
require 'active_support/hash_with_indifferent_access'
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

def unset_ivar(obj, var)
  obj.instance_variable_set "@#{var}", nil if obj.instance_variable_get "@#{var}"
end

