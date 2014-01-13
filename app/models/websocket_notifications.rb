# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class WebsocketNotifications < ActiveRecord::Observer
  #TODO näyttimelle kunnolla observointia...
  observe :slide, :master_group, :group, :presentation, :display, :override_queue


  def after_create(obj)
    event = :create
    data = {:id => obj.id}

		trigger obj, event, data
    display_datas(obj)
  end
  
  def after_update(obj)
    event = :update
    data = {:id => obj.id}
    
    trigger obj, event, data
    display_datas(obj)
    
		if obj.changed.include?('images_updated_at')
			Rails.logger.debug "-> Slide image has been updated, sendin notifications"
			obj.updated_image_notifications
		end
  end
  
  def after_destroy(obj)
    event = :destroy
    data = {:id => obj.id}
    
    trigger obj, event, data
    display_datas(obj)
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
