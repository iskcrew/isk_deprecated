class TubesockController < ApplicationController
	include Tubesock::Hijack

	def general
		hijack do |tubesock|
			# Listen on its own thread
			redis_thread = Thread.new do
				# Needs its own redis connection to pub
				# and sub at the same time
				Redis.new(Rails.configuration.x.redis).subscribe "isk_general" do |on|
					on.message do |channel, message|
						tubesock.send_data message
					end
				end
			end

			tubesock.onmessage do |m|
				begin
					Rails.logger.debug "Got websocket message: #{m}"
					msg = IskMessage.from_json(m)
					case msg.object
					when 'simple'
						msg.payload = SimpleSlide.create_svg(msg.payload)
						Rails.logger.debug "Sending data: #{msg}"
						tubesock.send_data msg.encode
					when 'template'
						data = msg.payload
						msg.payload = SlideTemplate.find(data[:template_id]).generate_svg(data)
						tubesock.send_data msg.encode
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
