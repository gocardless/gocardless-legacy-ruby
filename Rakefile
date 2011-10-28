require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb'].reject { |f| f.match(/seed|example/) }
end

