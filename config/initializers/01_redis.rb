# frozen_string_literal: true

# We have several gems (cashier, resque) using redis
# So set the redis for all of them here
if Rails.env.test?
  Rails.application.config.x.redis = { host: ENV["REDIS_HOST"] || "localhost", port: 6379, db: 2 }
else
  Rails.application.config.x.redis = { host: ENV["REDIS_HOST"] || "localhost", port: 6379 }
end

# Create a redis connection pool for cross-process messages
Rails.application.config.x.redis_pool = ConnectionPool.new(size: 20, timeout: 5) { Redis.new(Rails.configuration.x.redis) }
