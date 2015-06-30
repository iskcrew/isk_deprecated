class TubesockController < ApplicationController
	skip_before_filter :require_login
	include Tubesock::Hijack

	def chat
		hijack do |tubesock|
			# Listen on its own thread
			redis_thread = Thread.new do
				# Needs its own redis connection to pub
				# and sub at the same time
				Redis.new.subscribe "isk" do |on|
					on.message do |channel, message|
						tubesock.send_data message
					end
				end
			end

			tubesock.onmessage do |m|
				# pub the message when we get one
				# note: this echoes through the sub above
				Redis.new.publish "isk", m
				Rails.logger.debug "Foo: #{m}"
			end
      
			tubesock.onclose do
				# stop listening when client leaves
				redis_thread.kill
			end
		end
	end
end
