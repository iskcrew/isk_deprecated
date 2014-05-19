# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module ApplicationHelper
  
  def navigation_links
    controllers = ['Slides', 'Groups', 'Presentations', 'Displays', 'Schedules']
    admin_controllers = ['Users', 'Events']
    ret = String.new
    base_html_options = {class: 'ui-state-default ui-corner-top'}
		tabs = controllers
		tabs += admin_controllers if current_user.admin?
    tabs.each do |c|
			html_options = {class: 'ui-state-default ui-corner-top'}
			if controller.class.name.include?(c)
      	html_options[:class] <<  ' ui-tabs-active ui-state-active'
			end
      ret << content_tag('li', link_to(c, {:controller => c.downcase}), html_options)
    end
    return ret.html_safe 
  end
  
  def inactive_toggle(name, status)
    if status
      html="<a class='button inactive led green'>"
    else
      html="<a class='button inactive led off'>"
    end
    html << name << '</a>'
    return html.html_safe
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
        User.includes(:permissions).find_by_id(session[:user_id])
  end

  def current_event
      @_current_event ||= Event.current
  end
  
  
end
