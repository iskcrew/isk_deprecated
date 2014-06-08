class SlideTemplate < ActiveRecord::Base
	belongs_to :event
	
	serialize :data, HashWithIndifferentAccess
	
	after_create :write_template
	
	FilePath = Rails.root.join('data','templates')
	
	def settings
		self[:data]
	end
	
	# Need to migrate from Parameters object to hash...
	def settings=(s)
		h = HashWithIndifferentAccess.new
		s.each_key do |key|
			h[key] = HashWithIndifferentAccess.new
			s[key].each_pair do |k, v|
				if [:edit,:multiline].include?(k.to_sym) && v.is_a?(String)
					h[key][k] = v.to_i == 1 ? true : false
				else
					h[key][k] = v
				end
			end
		end
		Rails.logger.debug h
		self[:data] = h
	end
	
	# Load the svg in
	def template
		return @_template if (@_template or self.new_record?)
		@_template = File.read(self.svg_filename) if File.exists?(self.svg_filename)
		
		return @_svg_data	
	end
	
	# Handle a uploaded file
	def upload=(upload)
		self.template = upload.read
	end
	
	
	def template=(svg)
		@_template = svg
		generate_settings
		write_template
	end
	
	# TODO: input validation
	def generate_svg(data)
		svg = REXML::Document.new(self.template)
		
		data.each_key do |k|
			svg.root.elements.each("//text[@id='#{k.to_s}']") do |e|
				set_text(e, data[k][:text], data[k][:color])
			end
		end
		
		return svg.to_s
	end
	
	# Filename to store the svg template file in
	def filename
		FilePath.join "slide_template_#{self.id}.svg"
	end
	
	private
	
	def data
		self[:data]
	end
	
	def data=(val)
		self[:data] = val
	end
	
	# Extract all text fields from the svg template and
	# generate a settings hash based on that
	def generate_settings
		s = HashWithIndifferentAccess.new
		svg = REXML::Document.new(@_template)
		svg.root.elements.each('//text') do |e|
			s[e.attributes['id'].to_sym] = {
				edit: false, 
				multiline: false,
				color: 'Gold', 
				default: REXML::XPath.match(e,'.//text()').join.strip
			}
		end
		self[:data] = s
	end
	
	def write_template
		unless self.new_record?
			File.open(self.filename, 'w') do |f|
				f.write @_template
			end
		end
	end
	
	def set_text(element, text, color)
		# Clear tspans
		element.elements.each do 
			element.delete_element('*')
		end
		
		element.text = ""
		element.attributes['sodipodi:linespacing'] = '125%'
		
		first_line = true
		
		text.each_line do |l|
			row = element.add_element 'tspan'
			row.attributes['x'] = element.attributes['x']
			row.attributes['sodipodi:role'] = "line"
			row.attributes["xml:space"] = "preserve"
			
			#First line requires little different attributes
			if first_line
				first_line = false
			else
				row.attributes['dy'] = '1em'
			end

			parts = l.split(/<([^>]*)>/)
			parts.each_index do |i|
				ts = row.add_element 'tspan'
				if color && (i%2 == 1)
					ts.attributes['fill'] = color
				end
				ts.text = parts[i]
			end
		end
		
		return
	end
end
