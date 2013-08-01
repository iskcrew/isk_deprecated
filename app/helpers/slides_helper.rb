module SlidesHelper
  
  def slide_preview_image_tag(slide)
    html_options = {
      :class => 'preview ' + (slide.public ? 'slide-public' : 'slide-hidden'),
      :id => 'slide_preview_' + slide.id.to_s
    }
    
    if slide.ready
      url = url_for(:controller => :slides, :action => :preview, :id => slide.id, :t => slide.images_updated_at.to_i)
    else
      url = '/wait.gif'
    end
    
    return image_tag url, html_options
    
  end

  def slide_thumb_image_tag(slide)
    html_options = {
      :class => 'thumb ' + (slide.public ? 'slide-public' : 'slide-hidden'),
      :id => 'slide_thumb_' + slide.id.to_s
    }
		if slide.ready
      url = url_for(:controller => :slides, :action => :thumb, :id => slide.id, :t => slide.images_updated_at.to_i)
    else
    	url ='/wait.gif'
		end
		return image_tag url, html_options
  end


  
  def slide_full_image_tag(slide)
    image_tag url_for(:controller => :slides, :action => :full, :id => slide.id, :t => slide.images_updated_at.to_i), {:class => 'fullSlide', :id => 'slide_full_' + slide.id.to_s}
  end
  
  
  def slide_preview_to_show_tag(slide)
    html_options = {
      :title => 'Click to show slide details',
      :class => 'slide-preview-to-show'
    }
    url_options = {
      :controller => :slides,
      :action => :show,
      :id => slide.id
    }
    return link_to slide_preview_image_tag(slide), url_options, html_options
  end

  def slide_thumb_to_show_tag(slide)
    html_options = {
      :title => 'Click to show slide details',
      :class => 'slide-preview-to-show'
    }
    url_options = {
      :controller => :slides,
      :action => :show,
      :id => slide.id
    }
    return link_to slide_thumb_image_tag(slide), url_options, html_options
  end

  
  
  def slide_preview_to_full_tag(slide)
    html_options = {
      :title => 'Click to show full size slide image',
      :class => 'slide-preview-to-full'
    }
    url_options = {
      :controller => :slides,
      :action => :full,
      :id => slide.id
    }
    return link_to slide_preview_image_tag(slide), url_options, html_options
  end
    
  def group_link_tag(g)
    html = 'Group:' 
    html << link_to(g.name, {:controller => :groups, :action => :show, :id => g.id}, {:name => 'group_' + g.id.to_s} )
    html << " Slides:" << g.slides.public.count.to_s << '/' << g.slides.count.to_s
    return html.html_safe
  end
  
  def simple_color_select(f, color)
    f.select :color, options_for_select(simple_colors, color)
  end
  
  def simple_text_size_select(f, size)
    f.select :text_size, options_for_select(simple_text_sizes, size)
  end
  
  def simple_text_align_select(f, align)
    f.select :text_align, options_for_select(simple_aligns, align)
  end
  
  def hide_button_or_status(s, remote = false)
    if s.can_edit? current_user
      return slide_toggle_button('Public', s, :public)
	  elsif s.can_hide?(current_user) && s.public == true
	    return toggle_link_to 'Public', s.public, {:controller => :slides, :action => :hide, :id => s.id}, :method => :post, :remote => true, :confirm => "Are you sure you want to hide this slide? You cannot publish it later!"
    else
	    return inactive_toggle('Public', s.public)
    end
  end
  
  def slide_toggle_button(name, slide, attrib)
    toggle_link_to name, slide.send(attrib), {:controller => :slides, :action => :update, :id => slide.id, :slide => {attrib => !slide.send(attrib)}}, :method => :put, :remote => true
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
  
  def slide_filter_links(filter)
    html = String.new
    html << link_to('All slides', {:action => :index}, :class => (filter ? nil : 'current'))
    html << link_to('Thrashed', {:action => :index, :filter => 'thrashed'}, :class => (filter == :thrashed ? 'current' : nil))

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
