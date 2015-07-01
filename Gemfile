source 'https://rubygems.org'

gem 'rails', '~> 4.2.1'

# Database interfaces
# gem 'sqlite3'
gem 'pg', '~> 0.18.2'

# For migrating from mysql to postgresql
# gem 'yaml_db', github: 'jetthoughts/yaml_db', ref: 'fb4b6bd7e12de3cffa93e0a298a1e5253d7e92ba'
# gem 'mysql2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby
gem "libv8", '3.16.14.7'
gem "therubyracer", :require => 'v8'


# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.3'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.1',          group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.10'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

#### END OF RAILS DEFAULT GEMFILE

# Twitter bootstrap for base css styling
gem 'bootstrap-sass'
# Bootstrap aware formbuilder 
gem 'bootstrap_form'

# Nokogiri for XML processing
gem 'nokogiri'

# font-awesome-sass for icons
gem 'font-awesome-sass'

# Better memcached interface
gem 'dalli'

# Sorting slides in groups etc
gem 'ranked-model'

# Use thin as the webserver
gem 'thin'

# f.error_messages
gem 'dynamic_form'

# Calculate difference between two timestamps
gem 'time_diff', '~> 0.3'

# Slim template engine
gem 'slim'
# Generators for slim templates instead of erb
gem 'slim-rails'

gem 'websocket-rails', github: 'depili/websocket-rails', branch: 'channel_token_fix'

# For background stuff
gem 'resque'
gem 'daemons'
gem 'daemon'

# For monitorin scripts
gem 'highline'

# Better caching
gem 'cashier'

# for zipping all slides in a group or presentation
gem 'rubyzip', require: 'zip'

# For simple-edit previews to work in development
gem 'rack-rewrite'

# Pry for better console
gem 'pry-rails'

group :development do
  gem "rails-erd"
  gem 'web-console'
end

# Profiling support
group :profile do
  gem 'ruby-prof'
	gem 'request_profiler', :git => 'git://github.com/cheald/request_profiler.git'
end

# More compact logging
gem "lograge"

# Color output for our logs
gem 'colorize'

# RRD for statistics collection
gem 'rrd-ffi', group: :stats

group :test do
	# Color for minitest output
	gem 'minitest-reporters'
	
	# Code coverage report generator
	gem 'simplecov', :require => false
	
	# We do loads in after_commit callbacks so need to include them in tests
	gem 'test_after_commit'
end