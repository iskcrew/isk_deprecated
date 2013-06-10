class SimpleSlide < SvgSlide
  
  TypeString = 'simple'
  
  @slidedata = nil

  DefaultSlidedata = {:heading => 'Slide heading', :text => 'Slide contents with <highlight>', :color => 'Red', :text_size => 48, :text_align => 'Left'}

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
    return @slidedata unless @slidedata.nil?
    if File.exists? self.data_filename.to_s
      return @slidedata = YAML.load(File.read(self.data_filename))
    else
      return @slidedata = SimpleSlide::DefaultSlidedata
    end
  end
  
  def slidedata=(d)
    
    #Make sure new data has all the keys before saving.
    self.slidedata.each_key do |k|
      d[k] ||= self.slidedata[k]
    end

    d.keep_if do |k, v|
      SimpleSlide::DefaultSlidedata.keys.include? k
    end

  
    @slidedata=d
    
    File.open(self.data_filename,  'w') do |f|
      f.write d.to_yaml
    end
    
  end
  
end