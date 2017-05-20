# ISK - A web controllable slideshow system
#
# has_slidedata.rb - Shared functionality of storing variable
# data of the slide outside of the db.
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module HasSlidedata
  # This module depends on the class setting DefaultSlidedata hash.
  # When new data is entered it's checked against the default hash and all
  # keys that are not also present in the default are dropped.
  # If necessarry the values are merged so that submitting a incomplete set
  # of data doesn't wipe others away.

  extend ActiveSupport::Concern

  included do
    # Register callbacks on the model we are included on
    after_create :write_slidedata
  end

  # We need the .base_class to find the constant in the base class of the STI tree..
  def data_filename
    self.class.base_class::FilePath.join("#{filename}_data")
  end

  # Read and memoize the slidedata
  def slidedata
    return @_slidedata if @_slidedata.present?
    if !self.new_record? && File.exist?(self.data_filename.to_s)
      @_slidedata = YAML.load(File.read(self.data_filename))
    end
    return @_slidedata.blank? ? default_slidedata() : @_slidedata
  end

  # Write new slidedata and sanitize the keys in it.
  def slidedata=(d)
    # Merge the new data with the old slidedata, if a key is in both
    # the new contents is kept.
    d = slidedata.merge(d)

    if d.key? :url
      if d[:url] != self.slidedata[:url]
        @_needs_fetch = true
        self.ready = false
      end
    end

    @_slidedata = d

    # Mark the slide as not ready as its data has changed
    self.ready = false
    write_slidedata
  end

  def generate_svg
    self.template.generate_svg(self.slidedata)
  end

private

  # Sanitalize the data hash, only keep keys that exist in the default hash
  def sanitalize_slidedata(d)
    if d.nil?
      d = default_slidedata
    end

    d.keep_if do |k, v|
      default_slidedata.key? k
    end
    return d
  end

  def default_slidedata
    self.class::DefaultSlidedata
  end

  def write_slidedata
    return if self.new_record?
    File.open(self.data_filename, "w") do |f|
      f.write sanitalize_slidedata(@_slidedata).to_yaml
    end
  end
end
