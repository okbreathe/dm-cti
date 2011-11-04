source "http://rubygems.org"

DM_VERSION = '>= 1.2.0'

gem 'dm-validations', DM_VERSION
gem 'dm-constraints', DM_VERSION
gem 'dm-ar-finders', DM_VERSION
gem 'activesupport', ">=3.0.0"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "minitest", ">= 0"
  gem "minitest-rg"
  gem "bundler", "~> 1.0.0"
  gem "jeweler", "~> 1.6.4"
  gem "rcov", ">= 0"
  gem 'rr'
  gem 'dm-sqlite-adapter',    DM_VERSION
  gem 'dm-postgres-adapter',    DM_VERSION
  gem 'dm-migrations',        DM_VERSION
end
