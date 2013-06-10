class SvgSlide < Slide
  
  TypeString = 'svg-edit'

  @_svg_data = nil
#TODO: svg-datan käsittely tänne kontrollerista
  
  def initialize
    super
    self.is_svg = true
  end
    
  def to_inkscape_slide!
    return nil unless self.is_svg?
    
    svg = REXML::Document.new(File.read(self.svg_filename))
    
    svg = metadata_contents(svg)
    
    svg = inkscape_modifications(svg)
    
    svg_data = String.new
    svg.write svg_data
    
    svg_data.gsub!('FranklinGothicHeavy', 'Franklin Gothic Heavy')
    
    File.open(self.svg_filename, 'w') do |f|
      f.write svg_data
    end
    
    self.type = InkscapeSlide.model_name
    self.ready = false
    self.save!
    
    #Kuvien generointi failaa jos ei anneta oikeaa luokkaa...
    is = InkscapeSlide.find(self.id)
    is.delay.generate_images
  end

  def to_simple_slide!
    return nil unless self.is_svg?

    svg = REXML::Document.new(File.read(self.svg_filename))
    

    return nil unless svg.root.elements.to_a('//image').count = 1 #jos on muuta kuin taustakuva niin SEIS

    text_nodes = svg.root.elements.to_a('//text')
    
    return nil unless text_nodes.count > 0 #Pitää olla tekstiä
    
    header = text_nodes[0].elements.collect('//tspan'){|e| e.texts.join(" ")}.join(" ").strip
      
    text_nodes.delete_at(0)
      
    text = String.new
    text_nodes.each do |n|
      text << n.elements.collect('//tspan'){|e| e.texts.join(" ")}.join(" ").strip << " "
    end
    text.strip!
    
    
    
    self.type = SimpleSlide.model_name
    self.ready = false
    self.save!
    
    s = Slide.find(self.id) #muutettiin STI-tyyppiä
    
    s.slidedata({:heading => header, :text => text})
    
    
    
    return true
  end


  def sanitize!
    svg = REXML::Document.new(File.read(self.svg_filename))
    
    metadata_contents(svg)
    
    svg.root.elements.each('//text') do |e|
      e.delete_attribute 'xml:space'
    end

    svg_data = String.new
    svg.write svg_data

    svg_data.gsub!('FranklinGothicHeavy', 'Franklin Gothic Heavy')

    File.open(self.svg_filename, 'w') do |f|
      f.write svg_data
    end
  end


end
