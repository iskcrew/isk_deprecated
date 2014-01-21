# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

# Cashier gem allows us to expire cache fragments by tags
# The tags in use:
# slide_<id>:: 						Expires on any changes to this slide
# master_group_<id>:: 		Expires on any changes to this master_group
# presentation_<id>:: 		Expires on any changes to this presentation
# groups:: 								Expires on any change to any group
# slides:: 								Expires on any change to any slide 

class CacheObserver < ActiveRecord::Observer
	observe :slide, :master_group, :presentation
	
	# We use after_commit callback because we are using multi-threaded
	# server, and otherwise we might render the new fragments with old data
	def after_commit(obj)
		expire_cache(onj)
	end
	
	private
	
	def expire_cache(obj)
		if obj.is_a? Slide
			Cashier.expire "slides"
			self.presentations.each do |p|
				Cashier.expire p.cache_tag
			end
			
		elsif obj.is_a? MasterGroup
	  	Cashier.expire "groups"
			self.presentations.each do |p|
				Cashier.expire p.cache_tag
			end
	
		elsif obj.is_a? Presentation
			
		else
			raise ArgumentError, "Argument needs to be either a Slide, MasterGroup or Presentation"
		end
		
		Cashier.expire obj.cache_tag
		
	end


end