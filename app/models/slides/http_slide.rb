# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# http_slide.rb - STI slide type for dynamic content
# fetched over http
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class HttpSlide < ImageSlide
  require "net/http"
  require "net/https"

  TypeString = "http"

  DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(
    scale: "fit",
    background: "#000000",
    url: "http://",
    user: nil,
    password: nil
  ).freeze
  include HasSlidedata

  after_create do |s|
    s.send(:write_slidedata)
    s.fetch_later
  end

  validate :validate_url

  def clone!
    new_slide = super
    new_slide.slidedata = slidedata
    return new_slide
  end

private

  def generate_full_image
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
      self.image = StringIO.new(resp.body)
      self.ready = false
      save!
    else
      raise Slide::ImageError, "Error fetching slide data, http request didn't return OK status. URI=#{uri}"
    end
    super
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
