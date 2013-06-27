class IskdpyController < WebsocketRails::BaseController
  def current_slide
      d = Display.find(message)
      send_message :current_slide, d.current_slide.to_hash(d.presentation.duration)
  end
  
  def presentation
    d = Display.find(message)
    send_message :current_presentatin, d.presentation.to_hash
  end
  
  def display
    d = Display.find(message)
    send_message :display_data, d.to_hash
  end
end