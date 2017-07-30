# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class SvgSlide < Slide
  TypeString = "svg-edit".freeze
  @_svg_data = nil

  before_create do |slide|
    slide.is_svg = true
    true
  end

  def generate_full_image
    tmp_svg = Tempfile.new("isk-svg")
    tmp_svg.binmode
    svg = Nokogiri.XML(File.open(svg_filename))
    svg.search("image#background_picture").remove
    tmp_svg.write svg.to_xml
    tmp_svg.close
    tmp_file = Tempfile.new
    output = `#{inkscape_command_line(tmp_svg.path, tmp_file)}`
    raise Slide::ImageError, "Error converting the slide svg into PNG\nInkscape output:\n#{output}" unless $CHILD_STATUS.to_i.zero?

    FileUtils.mv tmp_file.path, transparent_filename
    # Tmpfile has 700 mode, we need to give other read permissions (mainly the web server)
    FileUtils.chmod 0o0644, transparent_filename
    tmp_svg.unlink
    tmp_file.unlink

    # Generate the normal unaltered full size image
    tmp_file = Tempfile.new("isk-image")
    output = `#{inkscape_command_line(svg_filename, tmp_file)}`
    return compare_new_image(tmp_file) if $CHILD_STATUS.to_i.zero?
    raise Slide::ImageError, "Error converting the slide svg into PNG\nInkscape output:\n#{output}"
  end

  def transparent_filename
    FilePath.join("#{filename}_transparent.png")
  end

private

  # Generate the full size slideimage from svg with inkscape
  def inkscape_command_line(svg_file, tmp_file)
    size = picture_sizes[:full]
    # Chance to proper directory
    command = "cd #{Slide::FilePath} && inkscape"
    # Export size
    command << " -w #{size.first} -h #{size.last}"
    # Export to file
    command << " -e #{tmp_file.path} #{svg_file}"
    # Supress std-out reporting
    command << " 2>&1"

    return command
  end
end

# Require all STI children, this needs to be done so that SvgSlide.count et al select all inherited types
require_dependency "inkscape_slide"
require_dependency "simple_slide"
require_dependency "schedule_slide"
