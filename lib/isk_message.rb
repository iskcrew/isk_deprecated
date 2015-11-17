# ISK - A web controllable slideshow system
#
# Class for handling the websocket messages in ISK
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class IskMessage
	attr_accessor :object, :type, :payload

	def initialize(object, type, payload)
		@object = object
		@type = type
		@payload = HashWithIndifferentAccess.new(payload)
	end
	
	# Parse a new IskMessage instance from json string
	def self.from_json(message)
		m = JSON.parse(message)
		return IskMessage.new(*m)
	end
	
	# Encode the message into a json string ready for transmission
	def encode
		return [@object, @type, @payload].to_json
	end
	
	def to_s
		"#{@object}: #{@type} -> payload: #{@payload}"
	end
end