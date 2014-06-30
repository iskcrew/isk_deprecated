#
#  rubyzip.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-30.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# Configure the rubyzip gem used for generating zips of slides.

Zip.setup do |c|
	# Store unicode filenames
	c.unicode_names = true
	# Do not compress, just store (we are dealing with png files and the benefit of compression is neglible)
	c.default_compression = Zlib::NO_COMPRESSION
end