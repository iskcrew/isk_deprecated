class WebsocketNotifications < ActiveRecord::Observer
  #TODO näyttimelle kunnolla observointia...
  observe :slide, :master_group, :group, :presentation, :display


  def after_create(obj)
    event = :create
    data = {:id => obj.id}
    
    display_datas(obj)
    trigger obj, event, data
  end
  
  def after_update(obj)
    event = :update
    data = {:id => obj.id}
    
    display_datas(obj)
    trigger obj, event, data
  end
  
  def after_destroy(obj)
    event = :destroy
    data = {:id => obj.id}
    
    display_datas(obj)
    trigger obj, event, data
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
