# ISK - A web controllable slideshow system
#
# Helpers for catching redis.publish trafic in tests
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module	RedisTestHelpers
	ThreadTimeout = 0.2
	
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
		@subscriber.join ThreadTimeout
	end
	
	def redis_messages
		@subscriber[:messages]
	end
	
	def assert_one_isk_message(object, type)
		assert_equal 1, redis_messages.count, "Should have received one message"
		assert msg = IskMessage.from_json(redis_messages.first), "Message should be in proper format"
		assert_equal object, msg.object, "Message should be about #{object}"
		assert_equal type, msg.type, "Message should have type #{type}"
		return msg
	end
end