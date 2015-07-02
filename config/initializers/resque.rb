# Redis to use with Resque background tasks
Resque.redis = "#{Rails.configuration.x.redis[:host]}:#{Rails.configuration.x.redis[:port]}"