source :rubygems

gemspec

group :development do
  gem "guard", "~> 0.8.8"
  if RUBY_PLATFORM.downcase.include?("darwin")
    gem "guard-rspec", "~> 0.5.4"
    gem "rb-fsevent", "~> 0.4.3.1"
    gem "growl_notify", "~> 0.0.3"
  end
end
