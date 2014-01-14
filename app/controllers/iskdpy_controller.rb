# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class IskdpyController < WebsocketRails::BaseController
  
  #näytin esittäytyy ja alustaa itsensä
  def hello
    if connection.request.headers['HTTP_X_FORWARDED_FOR']
      ip = connection.request.headers['HTTP_X_FORWARDED_FOR']
    else
      ip = connection.request.ip
    end
    d = Display.hello(message[:display_name], ip, connection.id)
    trigger_success d.to_hash
  end
  
  
  #Näytin kertoo mitä kelmua se näyttää
  def current_slide
      d = Display.find(message[:display_id])
      if message[:override_queue_id]
        d.override_shown(message[:override_queue_id], connection.id)
      else
        d.set_current_slide(message[:group_id], message[:slide_id], connection.id)
      end
			
			data = {:display_id => d.id, :group_id => d.current_group_id, :slide_id => d.current_slide_id}
      WebsocketRails[d.websocket_channel].trigger(:current_slide, data)
      trigger_success data
  end
  
  def goto_slide
    d = Display.find(message[:display_id])
    
    data = message
    WebsocketRails[d.websocket_channel].trigger(:goto_slide, data)
    trigger_success data
  end
  
  #Näytin kertoo esittäneensä ohisyötön
  def override_shown
      Display.transaction do
        d = Display.find(message[:display_id])
        d.override_shown(message[:override_queue_id])
        d.save!
      end
      data = {:display_id => message[:display_id], :override_queue_id => message[:override_queue_id]}
      WebsocketRails[d.websocket_channel].trigger(:override_shown, data)
      trigger_success data
  end
  
  
  def presentation
    d = Display.find(message)
    trigger_success d.presentation.to_hash
  end
  
  #Lähetetään näyttimen serialisaatio pyydettäessä.
  def display_data
    d = Display.find(message)
    data = d.to_hash
    WebsocketRails[d.websocket_channel].trigger(:data, data)
    trigger_success data
  end
end
