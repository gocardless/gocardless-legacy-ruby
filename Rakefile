require 'yard'
require 'rspec/core/rake_task'

desc "Generate YARD documentation"
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb'].reject { |f| f.match(/seed|example/) }
end

desc "Run the specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
end

