# frozen_string_literal: true

rackup      DefaultRackup
port        ENV["PORT"] || 12765
environment ENV["RAILS_ENV"] || "development"

# Number of forked workers
workers Integer(ENV["WEB_CONCURRENCY"] || 2)
# Ruby threads per worker [initial, max]
threads 4, 16

# Preload the application, needed for STI to work properly
preload_app!

if (ENV["RAILS_ENV"] || "development") != "development"
  # Run as daemon
  daemonize true

  # Log puma startup etc.
  stdout_redirect "log/puma.log", "log/puma_error.log", true
else
  daemonize false
  quiet false
end
pidfile "tmp/pids/server.pid"
state_path "tmp/pids/puma.state"

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end
