source 'https://rubygems.org'
source "http://gems.github.com"

gem 'rails', '4.0.5'

# We use observers

gem 'rails-observers'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Better memcached interface
gem 'dalli'

# Database interfaces
gem 'sqlite3'
gem 'mysql2'

gem 'ranked-model'
gem 'rmagick', :require => 'RMagick'
gem 'thin'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'dynamic_form'
gem 'time_diff', '~> 0.2.2'

gem 'slim'

#jquer javascript libraries
gem 'jquery-ui-rails'
gem 'jquery-rails'

# Currently, websocket-rails 0.7.0 breaks sync between the threads horribly
gem 'websocket-rails', '~> 0.6.2'

# For background stuff
gem 'daemon'
gem 'rrd-ffi', :require => 'rrd'

# Better caching
gem 'cashier'

# For simple-edit previews to work in development
gem 'rack-rewrite', '~> 1.2.1'

group :development do
  gem "rails-erd"
end

# Code coverage report generator
gem 'simplecov', :require => false, :group => :test
# We do loads in after_commit callbacks so need to include them in tests
gem 'test_after_commit', :group => :test

# Needed for rails 4.0
gem 'sprockets', '<= 2.11.0'

# Assets
gem "sass-rails"
gem 'coffee-rails'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", :require => 'v8'
gem 'uglifier'


# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
