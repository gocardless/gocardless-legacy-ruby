guard 'rspec', :version => 2, :cli => '--color --format doc' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/gocardless/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch('lib/gocardless.rb') { "spec/gocardless_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
end
