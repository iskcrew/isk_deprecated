# frozen_string_literal: true
#
#  zip_slides.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-30.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

module ZipSlides
  extend ActiveSupport::Concern

  # Generate a zip with all slides in the group
  def zip_slides
    t = Tempfile.new("isk_slide_zip")
    # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
    Zip::OutputStream.open(t.path) do |zos|
      i = 0
      self.slides.each do |slide|
        i += 1
        filename = "#{self.class.name.downcase}_#{self.name}_slide_%03d.png" % i
        # Create a new entry with some arbitrary name
        zos.put_next_entry(filename)
        # Add the contents of the file, don't read the stuff linewise if its binary, instead use direct IO
        zos.print IO.read(slide.full_filename)
      end
    end

    return t.read
  end

  # Run code in the context of model including this module
  included do
  end

  # Define class methods for the model including this
  module ClassMethods; end
end
