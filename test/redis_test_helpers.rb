# ISK - A web controllable slideshow system
#
# Helpers for catching redis.publish trafic in tests
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module	RedisTestHelpers
	class RedisTestSubscriber
		attr_reader :channel, :messages
		def initialize(channel)
			@channel = channel
			@messages = []
		end
		
		def process
			Redis.new(Rails.configuration.x.redis).subscribe(@channel) do |on|
				on.message do |channel, message|
					@messages.unshift message
					Thread.current[:messages] = messages
				end
			end
		end
	end
	
	
	def start_subscriber(channel = 'isk_general')
		@subscriber = Thread.new {
			RedisTestSubscriber.new(channel).process
		}
	end
	
	def stop_subscriber
		@subscriber.kill
	end
	
	def with_redis(channel = 'isk_general')
		start_subscriber(channel)
		yield
		@subscriber.join 1
	end
	
	def redis_messages
		@subscriber[:messages]
	end
end