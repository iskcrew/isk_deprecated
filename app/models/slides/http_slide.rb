# ISK - A web controllable slideshow system
#
# http_slide.rb - STI slide type for dynamic content
# fetched over http
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class HttpSlide < Slide
  require "net/http"
  require "net/https"

  TypeString = "http".freeze

  DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(url: "http://", user: nil, password: nil)
  include HasSlidedata

  after_create do |s|
    s.send(:write_slidedata)
    s.fetch_later
  end

  after_initialize do
    self.is_svg = false
    true
  end

  validate :validate_url

  def clone!
    new_slide = super
    new_slide.slidedata = slidedata
    return new_slide
  end

  def needs_fetch?
    return @_needs_fetch ||= false
  end

  def fetch!
    return false if slidedata.nil?

    uri = URI.parse(slidedata[:url])

    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    elsif uri.scheme != "http"
      raise ArgumentError "Unknown protocol"
    end

    request = Net::HTTP::Get.new(uri.request_uri)

    unless slidedata[:user].blank?
      request.basic_auth(slidedata[:user], slidedata[:password])
    end

    resp = http.request(request)

    if resp.is_a? Net::HTTPOK
      File.open(original_filename, "wb") do |f|
        f.write resp.body
      end
      self.is_svg = false
      self.ready = false
      save!
      generate_images_later
    else
      logger.error "Error fetching slide data, http request didn't return OK status"
      logger.error resp
      logger.error uri
    end
  end

  def fetch_later
    FetchJob.perform_later self
  end

private

  # FIXME: proper inheritance from imageslides!
  def generate_full_image
    bg_color = "#000000"
    scale = "fit"
    size = picture_sizes[:full].join("x")

    # Build the ImageMagick geometry string
    # The string is WIDTHxHEIGHT + scaling operator as follows
    # > to scale the image down if its height or width exceed the target
    # < will scale the image up if its height and width are smaller than the target
    # ! will scale to fit breaking aspect ratio
    geo_str = size
    case scale
    when "down"
      # Scale the image down if needed
      geo_str << '\>'
    when "up"
      # Only scale the image up if needed
      geo_str << '\<'
    when "stretch"
      # Stretch the image to fill the entire slide disregarding aspect ratio
      geo_str << "!"
    end

    # Generate the full sized image to a tempfile
    tmp_file = Tempfile.new("isk-image")
    command = "convert #{original_filename} -resize #{geo_str}"\
              " -background #{bg_color.shellescape} -gravity center"\
              " -extent #{size} #{tmp_file.path}"
    system command

    return compare_new_image(tmp_file)
  end

  # Validates the url
  def validate_url
    url = URI.parse slidedata[:url].strip
    unless ["http", "https"].include? url.scheme
      errors.add(:slidedata, "^URL scheme is invalid, must be http or https.")
    end
    errors.add(:slidedata, "^URL is invalid, missing host.") if url.host.blank?
  rescue URI::InvalidURIError
    errors.add(:slidedata, "^URL is invalid.")
  end
end
