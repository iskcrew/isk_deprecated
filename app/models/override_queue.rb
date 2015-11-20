# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class OverrideQueue < ActiveRecord::Base
	belongs_to :display, touch: true
	belongs_to :slide
	belongs_to :effect

	validates :duration, numericality: {:only_integer => true}
	#TODO: varmista että presis ja slide on olemassa
	
	include RankedModel
	ranks :position, :with_same => :display_id 
	
	# Send websocket messages on create and update
	include WebsocketMessages
	
	def to_hash
		h = self.slide.to_hash
		h[:override_queue_id] = self.id
		h[:duration] = self.duration
		h[:effect_id] = self.effect_id
		h[:group_name] = "OVERRIDE"
		return h
	end
	
end
