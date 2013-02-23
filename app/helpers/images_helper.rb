module ImagesHelper
  def image_preview_tag(id)
    link_to image_tag(url_for(:controller => :images, :action => :preview, :id => id), {:class => 'image_preview'}), :controller => :images, :action => :full, :id => id
  end
  
  def image_link(id)
    link_to 'Import to SVG-edit', {:controller => :images, :action => :full, :id => id}, :class => 'image_link'
  end
end
