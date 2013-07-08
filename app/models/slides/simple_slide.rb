class SimpleSlide < SvgSlide
  
  TypeString = 'simple'
  
  @slidedata = nil

  DefaultSlidedata = {:heading => 'Slide heading', :text => 'Slide contents with <highlight>', :color => 'Red', :text_size => 48, :text_align => 'Left'}

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
  

  
  def clone!
    new_slide = super
    new_slide.slidedata = self.slidedata
    return new_slide
  end
  
  
  def data_filename
    FilePath.join(self.filename + '_data')
  end
  
  def slidedata
    return @_slidedata unless @_slidedata.nil?
    if !self.new_record? && File.exists?(self.data_filename.to_s)
      return @_slidedata = YAML.load(File.read(self.data_filename))
    else
      return @_slidedata = SimpleSlide::DefaultSlidedata
    end
  end
  
  def slidedata=(d)
    #Varmisetetaan että kaikki hashin avaimet ovat symboleja
    d = d.each_with_object({}){|(k,v), h| h[k.to_sym] = v}


    # Jos jotain avainta ei ole uudessa hashissä käytetään vanhaa
    d = self.slidedata.merge(d)

    #Heitetään ylimääräiset avaimet pois ettei tallenneta paskaa levylle
    d.keep_if do |k, v|
      SimpleSlide::DefaultSlidedata.keys.include? k
    end
  
    @_slidedata=d
    
        
  end
  
  private
  
  def write_slidedata
    unless self.new_record?
      File.open(self.data_filename,  'w') do |f|
        f.write @_slidedata.to_yaml
      end
    end
  end
    
  
end