# We have several libraris (cashier,websocket-rails,resque) using redis
# So set the redis for all of them here
Rails.application.config.x.redis = {host: 'localhost', port: 6379}