source 'https://rubygems.org'
source "http://gems.github.com"

gem 'rails', '~> 4.1.1'

# Database interfaces
gem 'sqlite3'
gem 'mysql2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby
gem "therubyracer", :require => 'v8'


# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

#### END OF RAILS DEFAULT GEMFILE

# font-awesome-sass for icons
gem 'font-awesome-sass'

# We use observers
gem 'rails-observers'

# Better memcached interface
gem 'dalli'

# Sorting slides in groups etc
gem 'ranked-model'

# Slide image manipulations
gem 'rmagick', :require => 'RMagick'

# Use thin as the webserver
gem 'thin'

# f.error_messages
gem 'dynamic_form'

# Calculate difference between two timestamps
gem 'time_diff', '~> 0.2.2'

# Slim template engine
gem 'slim'

git 'https://github.com/depili/websocket-rails.git', branch: 'channel_token_fix' do
	gem 'websocket-rails'
end

# For background stuff
gem 'delayed_job_active_record'
gem 'daemons'
gem 'daemon'
gem 'rrd-ffi', :require => 'rrd'

# Better caching
gem 'cashier'

# for zipping all slides in a group or presentation
gem 'rubyzip', require: 'zip'

# For simple-edit previews to work in development
gem 'rack-rewrite', '~> 1.2.1'

group :development do
  gem "rails-erd"
end

# Code coverage report generator
gem 'simplecov', :require => false, :group => :test
# We do loads in after_commit callbacks so need to include them in tests
gem 'test_after_commit', :group => :test
