class IskdpyController < WebsocketRails::BaseController
  def current_slide
      d = Display.find(message)
      send_message :current_slide, {:current_slide => d.current_slide.to_json}
  end
  
  def presentation
    d = Display.find(message)
    send_message :current_presentatin, {:current_presentation => d.presentation.to_json}
  end
  
  def display
    d = Display.find(message)
    send_message :display_data, {:display_data => d.to_json}
  end
end