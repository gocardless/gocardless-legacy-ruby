require File.expand_path('../lib/gocardless/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_runtime_dependency 'oauth2', '~> 0.7'
  gem.add_runtime_dependency 'multi_json', '~> 1.0'

  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'mocha', '~> 0.9.12'
  gem.add_development_dependency 'yard', '~> 0.7.3'
  gem.add_development_dependency 'activesupport', '~> 3.1'

  gem.authors = ['Harry Marr', 'Tom Blomfield']
  gem.description = %q{A Ruby wrapper for the GoCardless API}
  gem.email = ['developers@gocardless.com']
  gem.files = `git ls-files`.split("\n")
  gem.homepage = 'https://github.com/gocardless/gocardless-ruby'
  gem.name = 'gocardless'
  gem.require_paths = ['lib']
  gem.summary = %q{Ruby wrapper for the GoCardless API}
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.version = GoCardless::VERSION.dup
end
