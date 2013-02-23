module DisplaysHelper
  
  def current_group_tag(d)
    if d.current_group_id == -1
      return link_to 'Override', {:action => :show, :id => d.id}, :class => 'override'
    elsif d.current_group
      return link_to d.current_group.name, :controller => :groups, :action => :show, :id => d.current_group.id
    else
      return 'UNKNOWN'
    end
  end
  
  def current_slide_tag(d)
    if d.current_slide
      return link_to d.current_slide.name, :controller => :slides, :action => :show, :id => d.current_slide.id
    else
      return 'UNKNOWN'
    end
  end
  
  def last_contact(d)
    if d.last_contact_at
      return I18n.l(d.last_contact_at, :format => :short).html_safe << '<br /> ('.html_safe << Time.diff(Time.now, d.last_contact_at, "%h:%m:%s")[:diff] << ' ago)'.html_safe
    else
      return 'UNKNOWN'
    end
  end
  
  
end
