module ApplicationHelper
  
  def navigation_links
    controllers = ['Slides', 'Groups', 'Presentations', 'Displays']
    ret = String.new
    html_options = Hash.new
    controllers.each do |c|
      html_options = controller.class.name.include?(c) ? {:class => 'current'} : {}
      ret << link_to(c, {:controller => c.downcase}, html_options)
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
  
  def preview_tag(slide)
    if slide.ready
      link_to image_tag(url_for(:controller => :slides, :action => :preview, :id => slide.id), {:class => 'preview'}), {:controller => :slides, :action => :full, :id => slide.id}, :title => 'Click to show full sized slide.'
    else
      html="<img class='preview' title='Slide preview not yet ready. Click to show full sized slide picture.' data-preview-url='" << url_for(:controller => :slides, :action => :preview, :id => slide.id)  << "' src='/wait.gif' />"
      return link_to html.html_safe, :controller => :slides, :action => :full, :id => slide.id
    end
  end
  
  def full_size_tag(id)
    image_tag url_for(:controller => :slides, :action => :full, :id => id), {:class => 'fullSlide'}
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
