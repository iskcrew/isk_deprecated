module SlidesHelper
  
  def preview_to_show_tag(slide)
    if slide.ready
      link_to image_tag(url_for(:controller => :slides, :action => :preview, :id => slide.id, :t => slide.images_updated_at.to_i), {:class => 'preview'}), {:controller => :slides, :action => :show, :id => slide.id}, :title => 'Click to show slide details.'
    else
      html="<img class='preview' title='Preview not yet available. Click to show slide details.' data-preview-url='" << url_for(:controller => :slides, :action => :preview, :id => slide.id)  << "' src='/wait.gif' />"
      return link_to html.html_safe, :controller => :slides, :action => :show, :id => slide.id
    end 
  end
  
  def group_link_tag(g)
    html = 'Group:' 
    html << link_to(g.name, {:controller => :groups, :action => :show, :id => g.id}, :name => g.name)
    html << " Slides:" << g.slides.public.count.to_s << '/' << g.slides.count.to_s
    return html.html_safe
  end
  
  def simple_color_select(color)
    select_options_tag 'color', simple_colors, :value=>color,:id=>'color', :title => 'Select the highlight color.'
  end
  
  def simple_text_size_select(size)
    select_options_tag 'text_size', simple_text_sizes, :value=>size, :id=>'text_size', :title => 'Select the font size for slide contents.'
  end
  
  def simple_text_align_select(align)
    select_options_tag 'text_align', simple_aligns, :value => align, :id => 'text_align', :title => 'Select the text alignment for slide contents.'
  end
  
  def hide_button_or_status(s, remote = false)
    if s.can_edit? current_user
      return hide_button(s)
	  elsif s.can_hide?(current_user) && s.public == true
	    return hide_button(s, true)
    else
	    return inactive_toggle('Public', s.public)
    end
  end
  
  def hide_button(s, confirm = false)
    options = {:id => s.id, :controller => :slides}
    options[:action]= (s.public ? :hide : :publish)
    html_options = {:method => :post, :remote => true}
    html_options[:confirm] = "Are you sure you want to hide this slide?" if confirm
    return toggle_link_to "Public", s.public, options, html_options 
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
  
  def slide_class(s)
    return 'Inkscape slide' if s.is_a? InkscapeSlide
    return 'Online simple editor slide' if s.is_a? SimpleSlide
    return 'Online SVG-editor slide' if s.is_a? SvgSlide
    return 'Video presentation' if s.is_a? VideoSlide
    return 'Automatically updating Http-slide' if s.is_a? HttpSlide
    return 'Plain bitmap slide' if !s.is_svg?
    return 'Unknown'
  end
  
  def filter_links(filter)
    html = String.new
    html << link_to('All slides', {:action => :index}, :class => (filter ? nil : 'current'))
    html << link_to('Slides I can edit', {:action => :index, :filter => 'edit'}, :class => (filter == :edit ? 'current' : nil))
    if current_user.has_role?('slide-hide')
      html << link_to('Slides I can hide', {:action => :index, :filter => 'hide'}, :class => (filter == :hide ? 'current' : nil))
    end
    return html.html_safe
  end
  
  private
  
  def simple_colors
    double_array ['Gold', 'Red', 'Orange', 'Yellow', 'PaleGreen', 'Aqua', 'LightPink']
  end
  
  def simple_aligns
    double_array ['Left', 'Left Centered', 'Centered', 'Right Centered', 'Right']
  end
  
  def simple_text_sizes
    double_array [48,50,60,70,80,90,100]
  end
  
  def double_array(v)
    ret = Array.new
    v.each do |v|
      ret << [v,v]
    end
    return ret
  end
end
