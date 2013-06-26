class WebsocketNotifications < ActiveRecord::Observer
  #TODO näyttimelle kunnolla observointia...
  observe :slide, :simple_slide, :svg_slide, :inkscape_slide, :http_slide, :video_slide, :master_group, :group, :presentation, :display

  def after_create(model)
    channel = model.base_class.name.downcase
    event = :create
    data = model.to_json
    
    WebsocketRails[channel].trigger(event, data)
  end
  
  def after_updata(model)
    channel = model.base_class.name.downcase
    event = :update
    data = model.to_json
    
    WebsocketRails[channel].trigger(event, data)
    
  end
  
  def after_destroy(model)
    channel = model.base_class.name.downcase
    event = :destroy
    data = model.id
    
    WebsocketRails[channel].trigger(event, data)
    
  end


  private

  def asd
    case 
    when model.is_a?(Slide)
    when model.is_a?(MasterGroup)
    when model.is_a?(Group)
    when model.is_a?(Presentation)
    when model.is_a?(Display)
    end
  end


end
