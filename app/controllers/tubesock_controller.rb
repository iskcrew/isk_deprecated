class TubesockController < ApplicationController
	include Tubesock::Hijack

	def general
		hijack do |tubesock|
			# Listen on its own thread
			redis_thread = Thread.new do
				# Needs its own redis connection to pub
				# and sub at the same time
				Redis.new.subscribe "isk_general" do |on|
					on.message do |channel, message|
						tubesock.send_data message
					end
				end
			end

			tubesock.onmessage do |m|
				# TODO: handle incoming messages
				# pub the message when we get one
				# note: this echoes through the sub above
				Rails.logger.debug "Got websocket message: #{m}"
			end
      
			tubesock.onclose do
				# stop listening when client leaves
				redis_thread.kill
			end
		end
	end
end
