source 'https://rubygems.org'
gemspec

group :compilation do
  unless /mingw|mswin/ =~ RUBY_PLATFORM
    gem 'rvm', '~> 1.11.3.9'
  end
  gem 'rake-compiler', '>= 0.7.1'
end
