# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class WebsocketNotifications < ActiveRecord::Observer
	#TODO näyttimelle kunnolla observointia...
	observe :slide, :master_group, :group, :presentation, :display, :override_queue, :display_state
		
	def after_commit(obj)
		Rails.logger.debug '-> Prosessing after_commit callback...'
		if obj.created_at == obj.updated_at
			Rails.logger.debug '	-> new record!'
			event = :create
		else
			Rails.logger.debug '	-> update'
			event = :update
		end
		
		data = {:id => obj.id}
		if obj.attributes.include? 'display_id'
			data[:display_id] = obj.display_id
		end
		
		
		trigger obj, event, data
		display_datas(obj)
		
		if obj.changed.include?('images_updated_at') && event == :update
			Rails.logger.debug "-> Slide image has been updated, sendin notifications"
			obj.updated_image_notifications
		end
	end


	private

	def trigger(obj, event, data)
		WebsocketRails[get_channel(obj)].trigger(event, data)
	end

	def get_channel(obj)
		return obj.class.base_class.name.downcase
	end

	def display_datas(obj)
		obj.displays.each do |d|
			data = d.to_hash
			WebsocketRails[d.websocket_channel].trigger(:data, data)
		end
	end

end
