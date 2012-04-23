require 'yard'
require 'rspec/core/rake_task'

desc "Generate YARD documentation"
YARD::Rake::YardocTask.new do |t|
  files = ['lib/**/*.rb', '-', 'CHANGELOG.md', 'LICENSE']
  t.files = files.reject { |f| f =~ /seed|example/ }
end

desc "Run an IRB session with gocardless pre-loaded"
task :console do
  exec "irb -I lib -r gocardless"
end

desc "Run the specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
end

