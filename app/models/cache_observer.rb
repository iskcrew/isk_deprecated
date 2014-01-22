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
	observe :slide, :master_group, :presentation, :user, :group, :permission
	
	def after_commit(obj)
		expire_cache(obj)
	end
	
	private
	
	def expire_cache(obj)
		if obj.is_a? Slide
			Cashier.expire "slides"
			
			#Expire presentation fragments
			obj.presentations.each do |p|
				Cashier.expire p.cache_tag
			end
			
			Cashier.expire obj.master_group.cache_tag
			if obj.changed.include? 'master_group_id'
				#We want to expire also the old group
				if g = MasterGroup.where(id: obj.master_group_id_was).first
					Cashier.expire g.cache_tag
				end
			end
			
		elsif obj.is_a? MasterGroup
	  	Cashier.expire "groups"
			obj.presentations.each do |p|
				Cashier.expire p.cache_tag
			end
	
		elsif obj.is_a? Presentation
			
		elsif obj.is_a? User
			
		elsif obj.is_a? Group
			Cashier.expire obj.presentation.cache_tag
		elsif obj.is_a? Permission
			Cashier.expire obj.user.cache_tag
		else
			raise ArgumentError, "Unexpected object class: " + obj.class.name
		end
		
		Cashier.expire obj.cache_tag
		
	end
	
end