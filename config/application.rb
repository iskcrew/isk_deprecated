# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
	# Require the gems listed in Gemfile, including any gems
	# you've limited to :test, :development, or :production.
	Bundler.require(:default, Rails.env)
end

module Isk
	class Application < Rails::Application
		# Settings in config/environments/* take precedence over those specified here.
		# Application configuration should go into files in config/initializers
		# -- all .rb files in that directory are automatically loaded.

		# Custom directories with classes and modules you want to be autoloadable.
		# config.autoload_paths += %W(#{config.root}/extras)

		# Only load the plugins named here, in the order given (default is alphabetical).
		# :all can be used as a placeholder for all plugins not explicitly named.
		# config.plugins = [ :exception_notification, :ssl_requirement, :all ]

		# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
		# Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
		config.time_zone = 'Helsinki'

		# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
		# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
		# config.i18n.default_locale = :de

		# Configure the default encoding used in templates for Ruby 1.9.
		config.encoding = "utf-8"

		# Configure sensitive parameters which will be filtered from the log file.
		config.filter_parameters += [:password, :svg_data, :svg]

		# Use SQL instead of Active Record's schema dumper when creating the database.
		# This is necessary if your schema can't be completely dumped by the schema dumper,
		# like if you have constraints or database-specific column types
		# config.active_record.schema_format = :sql

		# Enable the asset pipeline
		config.assets.enabled = true

		# Version of your assets, change this if you want to expire all your assets
		config.assets.version = '1.0'
		
		# Wrap form fields with errors in span.field_with_errors
		config.action_view.field_error_proc = Proc.new { |html_tag, instance| "<span class='field_with_errors'>#{html_tag}</span>".html_safe }

		# Add subdirectories of app/models to load paths, as we use them for STI classes
		config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]
		
		# Add app/mixins to load paths, we use that to store modules containing common functionality
		config.autoload_paths += Dir[Rails.root.join('app', 'mixins', '{**}')]
		
    # after_commit callbacks raise errors now
    config.active_record.raise_in_transactional_callbacks = true
    
		# Log display websocket actions on log/displays.log
		require 'display_logging'
		
		# Class for the websocket messages
		require 'isk_message'
		
		# Use sidekiq for background jobs
		config.active_job.queue_adapter = :resque
	end
end
