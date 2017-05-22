# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class TemplateSlide < InkscapeSlide
  TypeString = "template".freeze

  belongs_to :template, foreign_key: :foreign_object_id, class_name: "SlideTemplate"
  validates :template, presence: true

  include HasSlidedata

  # If our slidedata chances mark the slide as not ready when saving it.
  before_save do
    generate_svg if @_slidedata.present?
    true
  end

  def generate_images
    generate_svg
    super
  end

private

  def generate_svg
    self.svg_data = template.generate_svg(slidedata)
    write_svg_data
  end

  def default_slidedata
    default = ActiveSupport::HashWithIndifferentAccess.new
    template.fields.editable.each do |f|
      default[f.element_id.to_sym] = f.default_value
    end
    return default
  end
end

# Require all STI children, this needs to be done so that TemplateSlide.count
# et al select all inherited types
require_dependency "prize_slide"
