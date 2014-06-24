# 
#  image_slide.rb
#  isk
#  
#  Created by Vesa-Pekka Palmu on 2014-06-19.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
# 

class	ImageSlide < Slide
	TypeString = "image"
	
	ScalingOptions = [
		['Fit', 'fit'],
		['Down only', 'down'],
		['Up only', 'up'],
		['Stretch', 'stretch']
	]
	
	DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(
		scale: 'fit',
		background: '#000000'
	)
	include HasSlidedata
	
	# Validate and store a new image for the slide
	# image should be a IO-object
	def image=(image)
		begin
			picture = Magick::Image.from_blob(image.read).first
			picture.write(self.original_filename)
		rescue Magick::ImageMagickError
			if File.exists self.original_filename
				File::delete(@slide.original_filename)
			end
			raise
		end
	end
		
	private
	
	# Generate the full size slide preview
	def generate_full_image
		# Read the uploaded original image
		picture = Magick::ImageList.new(self.original_filename).first
		
		bg_color = self.slidedata[:background]
		scale = self.slidedata[:scale]
		size = picture_sizes[:full]
		
		# Build the ImageMagick geometry string
		# The string is WIDTHxHEIGHT + scaling operator as follows
		# > to scale the image down if its height or width exceed the target
		# < will scale the image up if its height and width are smaller than the target
		# ! will scale to fit breaking aspect ratio
		geo_str = size.join('x')
		case scale
		when 'down'
			# Scale the image down if needed
			geo_str << '>'
		when 'fit'
			# Scale the image to fit maintaining aspect ratio
			# Nothing to do
		when 'up'
			# Only scale the image up if needed
			geo_str << '<'
		when 'stretch'
			# Stretch the image to fill the entire slide disregarding aspect ratio
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