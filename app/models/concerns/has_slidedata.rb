# ISK - A web controllable slideshow system
#
# has_slidedata.rb - Shared functionality of storing variable
# data of the slide outside of the db.
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module  HasSlidedata
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
    self.class.base_class::FilePath.join(self.filename + '_data')
  end
  
  # Read and memoize the slidedata
  def slidedata
		return @_slidedata if @_slidedata.present?
    if !self.new_record? && File.exists?(self.data_filename.to_s)
      @_slidedata = YAML.load(File.read(self.data_filename))
		end
		return @_slidedata.blank? ? self.class::DefaultSlidedata : @_slidedata
  end
  
	# Write new slidedata and sanitize the keys in it.
  def slidedata=(d)
    if d.nil?
			d = self.class::DefaultSlidedata
		end
	
	
		# Merge the new data with the old slidedata, if a key is in both the new contents is kept.
		d = slidedata.merge(d)

    # Sanitize the data hash, only keep keys that exist in the default hash
		d.keep_if do |k, v|
      self.class::DefaultSlidedata.key? k
    end
  
    if d.key? :url
      # Validate that the url in the :url key is valid by trying to parse it.
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