# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class SimpleSlide < SvgSlide
  
  TypeString = 'simple'
  
  @slidedata = nil

  DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(:heading => 'Slide heading', :text => 'Slide contents with <highlight>', :color => 'Red', :text_size => 48, :text_align => 'Left').freeze
  include HasSlidedata

	BaseTemplate = Rails.root.join('data', 'templates', 'simple.svg')
	HeadingSelector = "//text[@id = 'header']"
	BodySelector = "//text[@id = 'slide_content']"
	MarginLeft = 30
	MarginRight = 30

	before_save do
		if @_slidedata.present?
			self.svg_data = SimpleSlide.create_svg(self.slidedata)
			self.ready = false
			return true
		end
	end


  after_create do |s|
    s.send(:write_slidedata)
  end


  attr_accessible :name, :description, :show_clock, :slidedata, :svg_data

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

		svg = REXML::Document.new(File.open(BaseTemplate))
		
		# FIXME: Read up on viewboxes and see how this relates to supporting different slide sizes
		svg.root.attributes['viewBox'] = "0 0 " + Slide::FullWidth.to_s + " " + Slide::FullHeight.to_s
		
		head = svg.elements[HeadingSelector]
		head.delete_element('*')
		head_tspan = head.add_element 'tspan'
		head_tspan.attributes['sodipodi:role'] = "line"
		head_tspan.attributes["xml:space"] = "preserve"
		head_tspan.text = heading
		
		
		body = svg.elements[BodySelector]
		body = set_text(body, text, color, text_size, text_align)
		
		svg.root.attributes['xmlns:sodipodi'] = 'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd'
		
		return svg.to_s
	end
	
	private
	
	def self.set_text(element, text, color = nil,size = nil, align = nil)
		element.elements.each do 
			element.delete_element('*')
		end
		element.text = ""
		element.attributes['sodipodi:linespacing'] = '125%'
		
		
		if size
			element.attributes['font-size'] = size
		else
			size = element.attributes['font-size']
		end
		
		first_line = true
		
		text.each_line do |l|
			row = element.add_element 'tspan'
			row.attributes['x'] = row_x align
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
		
		
		return set_align(element, align)
	end
	
	def self.row_x(align)
		if align
			case align.strip.downcase
			when 'right'
				return margin_right
			when 'centered'
				return (margin_right - margin_left) / 2 + margin_left
			else
				return margin_left
			end
		else
			return margin_left
		end
	end


	#TODO: left centered / right centered???
	def self.set_align(element, align)
		if align
			#TODO: move the coordinates to configuration			
			
			case align.strip.downcase
			when 'right'
				text_anchor = 'end'
			when 'centered'
				text_anchor = 'middle'
			else
				text_anchor = 'start'
			end
			
			element.attributes['x'] = row_x align
			element.attributes['text-anchor'] = text_anchor	
		end
		return element
	end
	
	def self.margin_left
		MarginLeft
	end
	
	def self.margin_right
		Slide::FullWidth - MarginRight
	end
   
	protected
	
  def rsvg_command(type)
    command = 'cd ' << FilePath.to_s << ' && inkscape'
    
    if type == :full
      command << ' -w ' << Slide::FullWidth.to_s
      command << ' -h ' << Slide::FullHeight.to_s
      command << ' -e ' << self.full_filename.to_s
      command << ' ' << self.svg_filename.to_s
			command << ' >/dev/null'
    end
    
    return command
  end  
	
		
		
end