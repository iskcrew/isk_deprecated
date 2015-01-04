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
		file = Tempfile.new('isk-image', encoding: 'binary')
		
		file.write image.read
		file.close
		
		# Verify image integrity
		command = "identify #{file.path} &> /dev/null"
		if system command
			FileUtils.copy file.path, self.original_filename
		else
			raise Slide::ImageError, "Invalid image received"
		end
		
	ensure
		file.unlink
	end
		
	private
	
	# Generate the full size slide preview
	def generate_full_image
		bg_color = self.slidedata[:background]
		scale = self.slidedata[:scale]
		size = picture_sizes[:full].join('x')
		
		# Build the ImageMagick geometry string
		# The string is WIDTHxHEIGHT + scaling operator as follows
		# > to scale the image down if its height or width exceed the target
		# < will scale the image up if its height and width are smaller than the target
		# ! will scale to fit breaking aspect ratio
		geo_str = size
		case scale
		when 'down'
			# Scale the image down if needed
			geo_str << '\>'
		when 'fit'
			# Scale the image to fit maintaining aspect ratio
			# Nothing to do
		when 'up'
			# Only scale the image up if needed
			geo_str << '\<'
		when 'stretch'
			# Stretch the image to fill the entire slide disregarding aspect ratio
			geo_str << '!'
		end
	
		# Generate the full sized image to a tempfile
		tmp_file = Tempfile.new('isk-image')
		command = "convert #{self.original_filename} -resize #{geo_str}"
		command << " -background '#{bg_color}' -gravity center -extent #{size} #{tmp_file.path}"
		system command
		
		return compare_new_image(tmp_file)
	end
	
end