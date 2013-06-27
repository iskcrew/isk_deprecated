class IskdpyController < WebsocketRails::BaseController
  
  #Näytin kertoo mitä kelmua se näyttää
  def current_slide
      Display.transaction do
        d = Display.find(message[:display_id])
        d.current_slide(message[:group_id], message[:slide_id])
        d.save!
      end
      
      WebsocketRails[d.websocket_channel].trigger(:current_slide, d.current_slide.to_hast(d.presentation.duration))
  end
  
  #Näytin kertoo esittäneensä ohisyötön
  def override_shown
      Display.transaction do
        d = Display.find(message[:display_id])
        d.override_shown(message[:slide_id])
        d.save!
      end
      
      WebsocketRails[d.websocket_channel].trigger(:override_shown, {:display_id => d.id, :override_id => message[:override_id]})
  end
  
  
  def presentation
    d = Display.find(message)
    send_message :current_presentatin, d.presentation.to_hash
  end
  
  #Lähetetään näyttimen serialisaatio pyydettäessä.
  def display_data
    d = Display.find(message)
    WebsocketRails[d.websocket_channel].trigger(:data, d.to_hash)
  end
end