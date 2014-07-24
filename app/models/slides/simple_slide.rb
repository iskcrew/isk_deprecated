# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class SimpleSlide < SvgSlide
	
	TypeString = 'simple'

	# Slidedata functionality
	DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(
		:heading => 'Slide heading', 
		:text => 'Slide contents with <highlight>', 
		:color => 'Red', 
		:text_size => 48, 
		:text_align => 'Left'
	)
	include HasSlidedata

	BaseTemplate = Rails.root.join('data', 'templates', 'simple.svg')
	HeadingSelector = "//text[@id = 'header']"
	BodySelector = "//text[@id = 'slide_content']"
	BackgroundSelector = "//image[@id = 'background_picture']"

	# If our slidedata chances mark the slide as not ready when saving it.
	before_save do
		if @_slidedata.present?
			self.svg_data = SimpleSlide.create_svg(self.slidedata)
			self.ready = false
		end
		true
	end

	def self.copy!(s)
		Slide.transaction do 
			orig_id = s.id
			
			simple = s.dup
			simple.save!
			simple.reload
			
			FileUtils.copy(s.svg_filename, simple.svg_filename)
			
			raise ApplicationController::ConvertError unless simple.to_simple_slide!
			
			simple = SimpleSlide.find(simple.id)
			
			s = Slide.find(orig_id)
			s.replacement_id = simple.id
			
			return simple
		end	 
	end
	
	
	def self.create_from_svg_slide(svg_slide)
		raise ApplicationController::ConvertError unless svg_slide.is_a? SvgSlide

		simple = SimpleSlide.new
		simple.name = svg_slide.name + " (converted)"
		simple.ready = false
		simple.show_clock = svg_slide.show_clock
		
		svg = REXML::Document.new(svg_slide.svg_data)
		

		#IF slide has other images than the background we have a problem
		unless svg.root.elements.to_a('//image').count == 1
			raise ApplicationController::ConvertError 
		end

		text_nodes = svg.root.elements.to_a('//text')
		
		#The slide needs to contain some text
		raise ApplicationController::ConvertError unless text_nodes.count > 0 
		
		header = text_nodes[0].elements.collect('tspan'){|e| e.texts.join(" ")}.join(" ").strip
			
		text_nodes.delete_at(0)
			
		text = String.new
		text_nodes.each do |n|
			text << n.elements.collect('tspan'){|e| e.texts.join(" ")}.join(" ").strip << " "
		end
		text.strip!
		
		simple.slidedata = {:heading => header, :text => text}
		simple.ready = false
		simple.save!
		
		return simple
	end

	
	def clone!
		new_slide = super
		new_slide.slidedata = self.slidedata
		return new_slide
	end
	
	
	# Take in the slide data and create a svg using them
	# This is used both to save the slide and to display a preview
	# in the simple editor page via websocket calls
	#TODO: create inkscape compliant svg!
	def self.create_svg(options)
		text_align = options[:text_align] || DefaultSlidedata[:text_align]
		text_size = options[:text_size] || DefaultSlidedata[:text_size]
		color = options[:color] || DefaultSlidedata[:color]
		heading = options[:heading] || ''
		text = options[:text] || ''
		
		current_event = Event.current
		settings = current_event.simple_editor_settings
		size = current_event.picture_sizes[:full]
		
		svg = prepare_template(settings, size, current_event.background_image)
		
		head = svg.elements[HeadingSelector]
		head = set_text(head, heading, settings[:heading][:coordinates].first, color, settings[:heading][:font_size])
		
		# Find out the text x coordinate
		text_x = row_x(text_align, settings[:body][:margins])		
		body = svg.elements[BodySelector]
		body = set_text(body, text, text_x, color, text_size, text_align)
				
		return svg.to_s
	end
	
	private
	
	# Prepare the base template based on event config
	def self.prepare_template(settings, size, background_image)
		svg = REXML::Document.new(File.open(BaseTemplate))
		
		# Add sodipodi namespace
		svg.root.attributes['xmlns:sodipodi'] = 'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd'
				
		# Set dimensions
		svg.root.attributes['width'] = size.first
		svg.root.attributes['height'] = size.last
		
		# Set viewbox
		svg.root.attributes['viewBox'] = "0 0 #{size.first} #{size.last}"
		
		# Set background
		bg = svg.elements[BackgroundSelector]
		bg.attributes['xlink:href'] = background_image
		bg.attributes['x'] = 0
		bg.attributes['y'] = 0
		bg.attributes['width'] = size.first
		bg.attributes['height'] = size.last
		
		# Position header
		header = svg.elements[HeadingSelector]
		header.attributes['x'] = settings[:heading][:coordinates].first
		header.attributes['y'] = settings[:heading][:coordinates].last
		
		# Header font size
		header.attributes['font-size'] = settings[:heading][:font_size]
				
		# Position body
		body = svg.elements[BodySelector]
		body.attributes['y'] = settings[:body][:y_coordinate]
		
		# Clear child elements from header and body
		clear_childs(header)
		clear_childs(body)
		
		return svg
	end
	
	def self.set_text(element, text, text_x, color = nil,size = nil, align = nil)
		
		# Set default attributes
		element.attributes['sodipodi:linespacing'] = '125%'
		element.attributes['x'] = text_x
		
		if size
			element.attributes['font-size'] = size
		else
			size = element.attributes['font-size']
		end
		
		first_line = true
		
		text.each_line do |l|
			row = element.add_element 'tspan'
			row.attributes['x'] = text_x
			row.attributes['sodipodi:role'] = "line"
			row.attributes["xml:space"] = "preserve"
			
			#First line requires little different attributes
			if first_line
				first_line = false
			elsif l.strip.empty?
				row.attributes['font-size'] = (size.to_i * 0.4).to_i
				row.attributes['dy'] = '1em'
				l = ' '
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
		
		return set_text_anchor(element, align)
	end
	
	def self.row_x(align, margins)
		if align
			case align.strip.downcase
			when 'right'
				return margins.last
			when 'centered'
				return (margins.first + margins.last) / 2
			else
				return margins.first
			end
		else
			return margins.first
		end
	end
	
	# Clear child elements
	def self.clear_childs(e)
		# Clear child elements (delete_element deletes only one element)
		e.elements.each do
			e.delete_element('*')
		end
		e.text = ''
		
		return e
	end

	def self.set_text_anchor(element, align)
		if align
			case align.strip.downcase
			when 'right'
				text_anchor = 'end'
			when 'centered'
				text_anchor = 'middle'
			else
				text_anchor = 'start'
			end
			element.attributes['text-anchor'] = text_anchor 
		end
		return element
	end
	
	# Override the default image generator
	# FIXME: make inkscape the default for everyone and remove this
	def generate_full_image
		system inkscape_command_line
	end
 
end