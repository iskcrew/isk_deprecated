# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class VideoSlide < Slide
  TypeString = "video".freeze
  FilePath = Rails.root.join("data", "video")
  VideoThumbnail = Rails.root.join("data", "video", "no_video.png")

  after_initialize do
    self.is_svg = false
    self.show_clock = false
    true
  end

  def preview_filename
    return VideoThumbnail
  end

  def thumb_filename
    return VideoThumbnail
  end

  def generate_images
    # TODO
  end
end
