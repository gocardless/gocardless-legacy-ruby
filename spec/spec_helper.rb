require 'active_support/hash_with_indifferent_access'
require 'gocardless'

def stub_get(client, data)
  response = double
  response.stub(:parsed).and_return(data)

  token = client.instance_variable_get(:@access_token)
  token.stub(:get).and_return response
end

def unset_ivar(obj, var)
  obj.instance_variable_set "@#{var}", nil if obj.instance_variable_get "@#{var}"
end

shared_examples_for "it has a query method for" do |status|
  describe "##{status}?" do
    context "when #{status}" do
      let(:object) { described_class.new(:status => status) }
      specify { object.send("#{status}?").should be_truthy }
    end

    context "when not #{status}" do
      let(:object) { described_class.new }
      specify { object.send("#{status}?").should be_falsey }
    end
  end
end
