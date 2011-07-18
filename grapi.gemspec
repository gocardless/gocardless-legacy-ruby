require File.expand_path('../lib/grapi/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_runtime_dependency 'oauth', '~> 0.5.0.rc1'
  gem.add_runtime_dependency 'json', '~> 1.5.3'

  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'mocha', '~> 0.9.12'

  gem.authors = ["Harry Marr"]
  gem.description = %q{A Ruby wrapper for Grapi}
  gem.email = ['harry@groupay.co.uk']
  gem.files = `git ls-files`.split("\n")
  gem.homepage = 'https://github.com/groupay/grapi'
  gem.name = 'grapi'
  gem.require_paths = ['lib']
  gem.summary = %q{Ruby wrapper for Grapi}
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.version = Grapi::VERSION.dup
end
