# 
#  image_slide.rb
#  isk
#  
#  Created by Vesa-Pekka Palmu on 2014-06-19.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
# 

class	ImageSlide < Slide
	TypeString = "image"
	
	DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(
		scale: 'down',
		background: '#000000'
	)
	include HasSlidedata
	
	# Generate the slide images
	def generate_images
		generate_Full_image
		generate_previews
			
		self.ready = true
		self.images_updated_at = Time.now
		self.save!
	end
	
	private
	
	def generate_full_image
		# Read the uploaded original image
		picture = Magick::ImageList.new(self.original_filename).first
		
		bg_color = self.slidedata[:background]
		scale = self.slidedata[:scale]
		size = pictures[:full]
		
		# Build the ImageMagick geometry string
		# The string is WIDTHxHEIGHT + scaling operator as follows
		# > to scale the image down if its height or width exceed the target
		# < will scale the image up or down if needed
		# ! will scale to fit breaking aspect ratio
		geo_str = size.join('x')
		case scale
		when 'down'
			geo_str << '>'
		when 'fit'
			geo_str << '<'
		when 'stretch'
			geo_str << '!'
		end
		
		# Scale the image
		picture = picture.change_geometry!(geo_str) do |cols, rows, img|
			# resize our image
			img.resize!(cols, rows)
			# build the background
			bg = Magick::Image.new(*size) { self.background_color = bg_color }
			# center the image on our new background
			bg.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
 		end
		
		picture.write(self.full_filename)
		
	end
	
end