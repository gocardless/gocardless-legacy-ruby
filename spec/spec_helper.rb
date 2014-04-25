require 'active_support/hash_with_indifferent_access'
require 'gocardless'

def stub_get(client, data)
  response = mock
  response.stub(:parsed).and_return(data)

  token = client.instance_variable_get(:@access_token)
  token.stub(:get).and_return response
end

def unset_ivar(obj, var)
  obj.instance_variable_set "@#{var}", nil if obj.instance_variable_get "@#{var}"
end

