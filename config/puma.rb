# Number of forked workers
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
# Ruby threads per worker [initial, max]
threads 4,16

# Preload the application
preload_app!

# Run as daemon
daemonize true
pidfile "tmp/pids/server.pid"

rackup      DefaultRackup
port        ENV['PORT']     || 12765
environment ENV['RAILS_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end