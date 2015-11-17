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
				begin
					Rails.logger.debug "Got websocket message: #{m}"
					msg = JSON.parse(m)
					case msg[0]
					when 'simple'
						svg = SimpleSlide.create_svg(msg[1].symbolize_keys)
						tubesock.send_data ["simple", svg].to_json
					when 'template'
					end
				rescue
					Rails.logger.error "Error handling websocket message #{m}"
					redis_thread.kill
					tubesock.close
				end
			end
      
			tubesock.onclose do
				# stop listening when client leaves
				redis_thread.kill
			end
		end
	end
end
