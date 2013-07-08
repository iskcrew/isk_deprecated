class HttpSlide < Slide
  
  require 'net/http'
  require 'net/https'

  
  TypeString = 'http'
  
  DefaultSlidedata = {:url => 'http://', :user => nil, :password => nil}
  include HasSlidedata
  
  after_create do |s|
    s.send(:write_slidedata)
    s.delay.fetch!
  end

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
    
  def needs_fetch?
    return @_needs_fetch ||=false
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