require File.expand_path('../lib/gocardless/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_runtime_dependency 'oauth2', '~> 1.0'
  gem.add_runtime_dependency 'multi_json', '~> 1.10'

  gem.add_development_dependency 'rspec', '~> 2.13'
  gem.add_development_dependency 'yard', '~> 0.8'
  gem.add_development_dependency 'activesupport', '~> 3.2'
  gem.add_development_dependency 'rake', '~> 10.3'
  gem.add_development_dependency 'coveralls', '~> 0.7'

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
  gem.licenses = ['MIT']
end
