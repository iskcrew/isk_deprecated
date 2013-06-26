class WebsocketNotifications < ActiveRecord::Observer
  #TODO näyttimelle kunnolla observointia...
  observe :slide, :master_group, :group, :presentation, :display


  def after_create(obj)
    event = :create
    data = {:id => obj.id}
    
    trigger obj, event, data
  end
  
  def after_update(obj)
    event = :update
    data = {:id => obj.id}
    
    trigger obj, event, data
  end
  
  def after_destroy(obj)
    event = :destroy
    data = {:id => obj.id}
    
    trigger obj, event, data
  end


  private

  def trigger(obj, event, data)
    WebsocketRails[get_channel(obj)].trigger(event, data)
  end

  def get_channel(obj)
    return obj.class.base_class.name.downcase
  end

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
