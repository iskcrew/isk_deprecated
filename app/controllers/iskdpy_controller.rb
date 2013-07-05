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
      Display.transaction do
        d = Display.find(message[:display_id])
        d.set_current_slide(message[:group_id], message[:slide_id])
        d.save!
      end
      data(d.current_slide.to_hast(d.presentation.duration))
      WebsocketRails[d.websocket_channel].trigger(:current_slide, data)
      trigger_success data
  end
  
  #Näytin kertoo esittäneensä ohisyötön
  def override_shown
      Display.transaction do
        d = Display.find(message[:display_id])
        d.override_shown(message[:override_queue_id])
        d.save!
      end
      
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
