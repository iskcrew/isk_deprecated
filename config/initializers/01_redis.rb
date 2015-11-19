# We have several libraris (cashier,websocket-rails,resque) using redis
# So set the redis for all of them here
unless Rails.env.test?
	Rails.application.config.x.redis = {host: 'localhost', port: 6379}
else
	Rails.application.config.x.redis = {host: 'localhost', port: 6379, db: 2}
end

# Create a redis connection pool for cross-process messages
$redis_pool = ConnectionPool.new(size: 20, timeout: 5) { Redis.new(Rails.configuration.x.redis) }