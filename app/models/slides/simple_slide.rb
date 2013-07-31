class SimpleSlide < SvgSlide
  
  TypeString = 'simple'
  
  @slidedata = nil

  DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(:heading => 'Slide heading', :text => 'Slide contents with <highlight>', :color => 'Red', :text_size => 48, :text_align => 'Left').freeze
  include HasSlidedata


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
  
    
end