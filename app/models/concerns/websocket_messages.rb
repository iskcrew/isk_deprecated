#
#  websocket_messages.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-29.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# This module is responsible for sending websocket messages when a model is changed.
#

module WebsocketMessages
	extend ActiveSupport::Concern
	
	# Run code in the context of model including this module
	included do
		# Send the websocket messages after commit
		after_commit :send_create_message, on: :create
		after_commit :send_update_message, on: :update
	end
	
	# Define class methods for the model including this
	module ClassMethods
		
	end

	private
	
	def send_create_message
		send_messages(:create)
	end
	
	def send_update_message
		send_messages(:update)
	end

	# Send the standard websocket notifications when a object gets updated or created.
	def send_messages(event)
		Rails.logger.debug "Sending websocket messages for #{get_channel} id #{self.id}..."
		
		# Basic message data to send
		data = {:id => self.id}
		
		if self.attributes.include? 'display_id'
			data[:display_id] = self.display_id
		end
		
		if self.respond_to? :name
			data[:name] = self.name
		end
		
		# Add changed attibutes
		data[:changes] = {}
		self.previous_changes.each_pair do |k, v|
			data[:changes][k] = v.last unless (k == 'password') || (k == 'salt')
		end
		Rails.logger.debug "Sending #{data.to_s}"
		msg = IskMessage.new(get_channel, event, data)
		msg.send('isk_general')
		
		# If we have associated displays resend their data
		if self.respond_to? :displays
			display_datas
		end
		
		if self.previous_changes.include?('images_updated_at') && event == :update
			Rails.logger.debug "-> Slide image has been updated, sending notifications"
			self.updated_image_notifications
		end
	end

	def get_channel
		return self.class.base_class.name.downcase
	end

	def display_datas
		self.displays.each do |d|
			data = d.to_hash
			msg = IskMessage.new('display', 'data', data)
			msg.send(d.websocket_channel)
		end
	end

end