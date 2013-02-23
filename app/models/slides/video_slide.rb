class VideoSlide < Slide
  
  TypeString = 'video'

  FilePath = Rails.root.join('data','video')

  VideoThumbnail = Rails.root.join('public','no_video.png')

  def initialize
    super
    self.is_svg = false
    self.show_clock = false
  end

  def preview_filename
    return VideoThumbnail
  end
  
  def generate_images
    #TODO
  end
  
  

end