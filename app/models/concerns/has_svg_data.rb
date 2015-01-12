# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module HasSvgData
	extend ActiveSupport::Concern
	
	included do
		# Instance variable to store the svg data in memory between writes
		@_svg_data = nil
		
		# Register a after-create callback to write the svg data on new records
		after_create do 
			if @_svg_data
				write_svg_data
			end
		end
		
	end
	
	# Read the svg-data into memory on access in case we need it more than once
	# FIXME: Better handling of non-existant files?
	def svg_data
		return @_svg_data if (@_svg_data or self.new_record?)
		@_svg_data = File.read(self.svg_filename) if File.exists?(self.svg_filename)
		
		return @_svg_data
	end
	
	# Save a new svg file for the slide. Also store the data in memory.
	# We also mark the slide as not ready because the picture isn't current anymore and needs
	# to be regenerated.
	def svg_data=(svg)
		if self.svg_data != svg
			
			@_svg_data = svg
			write_svg_data
		
			self.ready = false
		end
	end
	
	# Filename to store the svg in.
	def svg_filename
		self.class::FilePath.join(self.filename + '.svg')
	end
	
	protected
	
	# Write the svg data into a file
	# We need to check if record is new, because we don't know the filename for the svg
	# before the record is saved.
	def write_svg_data
		unless self.new_record?
			File.open(self.svg_filename, 'wb') do |f|
				f.write @_svg_data
			end
		end
	end
	
	
	module ClassMethods
		
	end
	
end