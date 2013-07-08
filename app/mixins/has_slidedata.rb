module  HasSlidedata

  def data_filename
    self.class.base_class::FilePath.join(self.filename + '_data')
  end
  
  
  def slidedata
    return @_slidedata if @_slidedata
    if !self.new_record? && File.exists?(self.data_filename.to_s)
      return @_slidedata = YAML.load(File.read(self.data_filename))
    else
      return @_slidedata = self.class::DefaultSlidedata
    end
  end
  
  def slidedata=(d)
    #Varmisetetaan että kaikki hashin avaimet ovat symboleja
    d = d.each_with_object({}){|(k,v), h| h[k.to_sym] = v}


    # Jos jotain avainta ei ole uudessa hashissä käytetään vanhaa
    d = self.slidedata.merge(d)

    #Heitetään ylimääräiset avaimet pois ettei tallenneta paskaa levylle
    d.keep_if do |k, v|
      self.class::DefaultSlidedata.keys.include? k
    end
  
    if d.keys.include? :url
      #Varmistetaan että url on ok (heittää URI::InvalidURIError jos ei ole ok)
      URI::parse d[:url].strip
    
      if d[:url] != self.slidedata[:url]
        @_needs_fetch = true
        self.ready = false
      end
    end
    
    @_slidedata=d
    
    write_slidedata
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