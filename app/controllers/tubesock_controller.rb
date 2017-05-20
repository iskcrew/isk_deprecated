# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class TubesockController < ApplicationController
  include Tubesock::Hijack

  def general
    hijack do |tubesock|
      # Listen on its own thread
      redis_thread = Thread.new do
        # Needs its own redis connection to pub
        # and sub at the same time
        Redis.new(Rails.configuration.x.redis).subscribe "isk_general" do |on|
          on.message do |_channel, message|
            tubesock.send_data message
          end
        end
      end

      tubesock.onmessage do |m|
        begin
          Rails.logger.debug "Got websocket message: #{m}"
          msg = IskMessage.from_json(m)
          # we only care about commands
          return unless msg.object == "command"
          case msg.type
          when "simple_svg"
            msg = IskMessage.new("simple", "svg",
                                 SimpleSlide.create_svg(msg.payload))
            tubesock.send_data msg.encode
          when "template_svg"
            data = msg.payload
            msg = IskMessage.new("template", "svg",
                                 SlideTemplate.find(data[:template_id])
                                              .generate_svg(data))
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
