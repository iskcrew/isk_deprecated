module ApplicationHelper
  
  def navigation_links
    controllers = ['Slides', 'Groups', 'Presentations', 'Displays']
    admin_controllers = ['Users', 'Events']
    ret = String.new
    html_options = Hash.new
    controllers.each do |c|
      html_options = controller.class.name.include?(c) ? {:class => 'current'} : {}
      ret << link_to(c, {:controller => c.downcase}, html_options)
    end
    if current_user.admin?
      admin_controllers.each do |c|
        html_options = controller.class.name.include?(c) ? {:class => 'current'} : {}
        ret << link_to(c, {:controller => c.downcase}, html_options)
      end
    end
    return ret.html_safe 
  end
  
  def toggle_link_to(name, selected,options = {}, html_options = {})
    html_options[:class] = (selected ? 'button led green' : 'button led off')
    html_options[:title] = (selected ? 'Toggle this off' : 'Toggle this on')
    return link_to name, options, html_options
  end
  
  def authorized_users(obj)
    render :partial => 'shared/authorized_users', :locals => {:obj => obj}
  end
    
  
  def late_display_warning(d)
    link_text = (d.name || String.new) << " (" << d.ip << ") is more than " << Display::Timeout.to_s << " minutes late!"
    link_to link_text, :controller => :displays, :action => :show, :id => d.id
  end


  def select_options_tag(name='',select_options={},options={})
    #set selected from value
    selected = ''
    unless options[:value].blank?
      selected = options[:value]
      options.delete(:value)
    end
    select_tag(name,options_for_select(select_options,selected),options)
  end
  
  def current_user
      @_current_user ||= session[:user_id] &&
        User.includes(:roles).find_by_id(session[:user_id])
  end
  
  
end
