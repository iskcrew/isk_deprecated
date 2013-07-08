class HttpSlide < Slide
  
  require 'net/http'
  require 'net/https'
  
  TypeString = 'http'
  
  DefaultSlidedata = {:url => 'http://', :user => nil, :password => nil}
  @slidedata = nil

  attr_accessible :name, :description, :show_clock, :slidedata
  
  def clone!
    new_slide = super
    new_slide.slidedata = self.slidedata
    return new_slide
  end

  def initialize(data)
    super(data)
    self.is_svg = false
    self.ready = false
  end
  
  def data_filename
    FilePath.join(self.filename + '_data')
  end
  
  
  def slidedata
    return @_slidedata unless @_slidedata.nil?
    if File.exists? self.data_filename.to_s
      return @slidedata = YAML.load(File.read(self.data_filename))
    else
      return HttpSlide::DefaultSlidedata
    end
  end
  
  def needs_fetch?
    return @_needs_fetch ||=false
  end
  
  
  def slidedata=(d)
    #Varmisetetaan että kaikki hashin avaimet ovat symboleja
    d = d.each_with_object({}){|(k,v), h| h[k.to_sym] = v}


    # Jos jotain avainta ei ole uudessa hashissä käytetään vanhaa
    d = self.slidedata.merge(d)

    #Heitetään ylimääräiset avaimet pois ettei tallenneta paskaa levylle
    d.keep_if do |k, v|
      HttpSlide::DefaultSlidedata.keys.include? k
    end
  
  
    #Varmistetaan että url on ok (heittää URI::InvalidURIError jos ei ole ok)
    URI::parse d[:url].strip
    
    if d[:url] != self.slidedata[:url]
      @_needs_fetch = true
      self.ready = false
    end
    
    @_slidedata=d
    
    File.open(self.data_filename,  'w') do |f|
      f.write d.to_yaml
    end    
  end
  
  
  def fetch!
    return false if self.slidedata.nil?
    
    uri = URI.parse(self.slidedata[:url])

    http = Net::HTTP.new(uri.host, uri.port)

    case uri.scheme
    when 'http'
    when 'https'
      
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    else
      raise ArgumentError 'Unknown protocol'
    end

    request = Net::HTTP::Get.new(uri.request_uri)


    unless self.slidedata[:user].empty?
      request.basic_auth(self.slidedata[:user], self.slidedata[:password])
    end

    
    resp = http.request(request)
    
    
    if resp.is_a? Net::HTTPOK
      File.open(self.original_filename, 'wb') do |f|
        f.write resp.body
      end
      self.is_svg = false
      self.ready = false
      self.save!
      self.delay.generate_images
    else
      logger.error "Erro fetching slide data, http request didn't return OK status"
      logger.error resp
      logger.error uri
    end
  end

end