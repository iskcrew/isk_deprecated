module  HasSlidedata

  def data_filename
    self.class.base_class::FilePath.join(self.filename + '_data')
  end
  
  
  def slidedata
		return @_slidedata if @_slidedata
    if !self.new_record? && File.exists?(self.data_filename.to_s)
      @_slidedata = YAML.load(File.read(self.data_filename))
		end
		return @_slidedata.blank? ? self.class::DefaultSlidedata : @_slidedata
  end
  
  def slidedata=(d)
    if d.nil?
			d = self.class::DefaultSlidedata
		end
	
	
		# Jos jotain avainta ei ole uudessa hashissä käytetään vanhaa
    d = slidedata.merge(d)

    #Heitetään ylimääräiset avaimet pois ettei tallenneta paskaa levylle
    d.keep_if do |k, v|
      self.class::DefaultSlidedata.key? k
    end
  
    if d.key? :url
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