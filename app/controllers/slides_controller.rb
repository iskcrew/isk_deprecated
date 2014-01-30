# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class SlidesController < ApplicationController    
	before_filter :require_create, :only => [:new, :create]
	before_filter :require_admin, :only => [:deny, :grant, :to_inkscape]
	skip_before_filter :require_login, :only => [:svg_save, :preview, :full]
    
	def index
		if params[:filter] == "thrashed"
			@groups = [Event.current.thrashed]
			@filter = :thrashed
		else
			@groups = Array.new
			@groups << Event.current.ungrouped
			@groups << MasterGroup.current.order("LOWER(name), name").includes(:slides).all
			@groups.flatten!
		end
    
		respond_to do |format|
			format.js
			format.html
		end
	end

	def deny
		slide = Slide.find(params[:id], lock: true)
		user = User.find(params[:user_id], lock: true)
		slide.authorized_users.delete(user)
    
		redirect_to :back
	end
  
	def grant
		slide = Slide.find(params[:id], lock: true)
		user = User.find(params[:grant][:user_id], lock: true)
		slide.authorized_users << user
		
		redirect_to :back    
	end

	def add_to_group
		slide = Event.current.ungrouped.slides.find(params[:id], lock: true)
		require_edit(slide)
    
		group = Event.current.master_groups.find(params[:add_to_group][:group_id], lock: true)
		require_edit(group)
    
		group.slides << slide
		
		flash[:notice] = "Added slide " << slide.name << " to group " << group.name

		redirect_to :back
	end
  
	def add_to_override
		slide = Slide.current.find(params[:id], lock: true)
		display = Display.find(params[:add_to_override][:display_id], lock: true)
    
		raise ApplicationController::PermissionDenied unless display.can_override? current_user
    
		display.add_to_override(slide, params[:add_to_override][:duration].to_i)
    	
		unless display.do_overrides
			flash[:warning] = "WARNING: This display isn't currently showing overrides, displaying this slide will be delayed"
		end
		flash[:notice] = 'Added slide ' << slide.name << ' to override queue for display ' << display.name

		redirect_to :back
	end

	def hidden
		@slides = Slide.current.hidden.all
	end


	def hide
		slide = Slide.find(params[:id], lock: true)
    
		unless slide.can_hide? current_user
			flash[:error] = "Not allowed"
			redirect_to :back and return
		end
    
		slide.public = false
		slide.save!
		
		respond_to do |format|
			format.html {redirect_to :back}
			format.js {render :show}
		end
	end
    
	def svg_edit
		@slide = Slide.find(params[:id])
    
		require_slide_edit(@slide)
    
		if @slide.type == SimpleSlide.sti_name
			redirect_to :action => :edit, :id => @slide.id
		else
			flash[:error] = "This slide isn't a simple slide, you cannot edit it online!"
			redirect_to :action => :show, :id => @slide.id
		end
    
	end
  
	def svg_data
		@slide = Slide.find(params[:id])
		@slide.update_metadata! if @slide.is_a? InkscapeSlide
    
		send_file @slide.svg_filename, :disposition => 'attachment'
	end
  
	#TODO: oikeudet, sisääntulevan inkscape-svg:n validointi
	def svg_save
		@slide = Slide.find(params[:id], lock: true)

		@slide.svg_data = params[:svg]
		@slide.save!
		@slide.delay.generate_images
 
		render :nothing => true
	end

	def to_inkscape
		slide = SvgSlide.find(params[:id])
		ink = InkscapeSlide.create_from_simple(slide)
		slide.replace! ink
		flash[:notice] = "Slide was converted to inkscape slide"
    
		redirect_to :action => :show, :id => ink.id
	end
  
	def to_simple
		slide = SvgSlide.find(params[:id])
		begin
			Slide.transaction do
				simple = SimpleSlide.create_from_svg_slide(slide)
				slide.replace! simple
				
				flash[:notice] = "Slide was converted simple slide"
      
				redirect_to :action => :edit, :id => simple.id
      
			end
			
		rescue ConvertError
			flash[:error] = "Conversion error, maybe slide has images?"
			redirect_to :action => :show, :id => slide.id
  
		end
	end
  
  
	def thrashed
		@slides = Slide.thrashed.order("name ASC")
	end
  
	def show
		@slide = Slide.find(params[:id])
    
		respond_to do |format|
			format.html
			format.js
		end
	end
  
	def new
		@slide = Slide.new
    
		unless Slide.admin? current_user
			#sallitaan vain yksinkertaisten ryhmättömien kelmujen luonti
			render :new_simple
			return
		end
    
	end
  
	def destroy
		@slide = Slide.find(params[:id], lock: true)
		require_slide_edit @slide
    
		@slide.destroy
		@slide.save!
      
		redirect_to :action => :show, :id => @slide.id
	end
  
	def undelete
		@slide = Slide.find(params[:id], lock: true)
    
		require_slide_edit(@slide)
    
		@slide.undelete
		@slide.save!
	  
		redirect_to :action => :show, :id => @slide.id
	end
    
	def clone
		old_slide = Slide.find(params[:id])
		slide = old_slide.clone!
		slide.delay.generate_images unless slide.ready
		flash[:notice] = "Slide cloned."
    
		redirect_to :action => :show, :id => slide.id
	end
  
  
	def create
		begin
			#transaktiona jotta kantaan ei mene mitään jos tiedostosta ei saada kuvaa ulos
			Slide.transaction do
        
				unless params[:create_type] == 'simple' || Slide.admin?(current_user)
					raise ApplicationController::PermissionDenied
				end
        
				#Luodaan oikeanlainen slide
				case params[:create_type]
				when 'simple'
					@slide = SimpleSlide.new(params[:slide])
				when 'http_slide'
					@slide = HttpSlide.new(params[:slide])
				when 'empty_file'
					@slide = InkscapeSlide.new(params[:slide])
				else
					@slide = Slide.new(params[:slide])
				end
        
				unless @slide.save
					if Slide.admin? current_user
						render :action => :new and return
					else
						render :new_simple and return
					end
				end
        
				@slide.reload(lock: true)
				
				
				case params[:create_type]
				when 'empty_file'
					FileUtils.copy(InkscapeSlide::EmptySVG, @slide.svg_filename)
				when 'image'
					File.open(@slide.original_filename, 'w+b') do |f|
						f.puts params[:upload].read
					end
				end
                
				unless @slide.can_edit? current_user
					@slide.authorized_users << current_user
				end
        
        
			end #transaktio
      
			if @slide.is_a? HttpSlide
				@slide.delay.fetch!
			else
				@slide.delay.generate_images
			end
      
			redirect_to :action => :show, :id => @slide.id
      
		rescue Magick::ImageMagickError
			#image invalid
			File::delete(@slide.original_filename)
			flash[:error] = "Error creating slide, invalid image file"
			render :action => :new
		end
    
	end
  
	
	#TODO: move ungroup -action into slide model
	def ungroup
		slide = Slide.find(params[:id], lock: true)
		require_edit(slide)
		slide.master_group_id = Event.current.ungrouped.id
		slide.save!
	
		respond_to do |format|
			format.html {redirect_to :back}
			format.js {render :index}
		end
	end
  
	def preview
		@slide = Slide.find(params[:id])
		if stale?(:last_modified => @slide.images_updated_at.utc, :etag => @slide)

			respond_to do |format|
				format.html {
					if @slide.ready
						send_file(@slide.preview_filename, {:disposition => 'inline'})
					else
						send_file(Rails.root.join('data','no_image.jpg'), {:disposition => 'inline'})
					end
				}
				format.js {render :show}
			end
		end
	end

	def thumb
		@slide = Slide.find(params[:id])
		if stale?(:last_modified => @slide.images_updated_at.utc, :etag => @slide)

			respond_to do |format|
				format.html {
					if @slide.ready
						send_file(@slide.thumb_filename, {:disposition => 'inline'})
					else
						send_file(Rails.root.join('data','no_image.jpg'), {:disposition => 'inline'})
					end
				}
				format.js {render :show}
			end
		end
	end



	def preview_ready
		slide = Slide.find(params[:id])
    
		if request.xhr?
			if slide.ready
				render :text => (url_for :action => :preview, :id => params[:id])
			else
				render :nothing => true, :status => 404
			end
		else
			render :text => (slide.ready ? 'true' : 'false')
		end
	end
  
	def full
		begin
			slide = Slide.find(params[:id])
			if slide.ready
				send_file(slide.full_filename, {:disposition => 'inline'})
			else
				render :nothing => true, :status => 503
			end
		rescue ActiveRecord::RecordNotFound, ActionController::MissingFile
			render :nothing => true, :status => 404
		end
	end
  
	def edit
		@slide = Slide.find(params[:id])
  
		require_slide_edit(@slide)
    
		case @slide.type
		when SimpleSlide.sti_name
			render :simple_edit and return
		when HttpSlide.sti_name
			render :http_edit and return
		end
	end
  
	def update
		Slide.transaction do

			@slide =Slide.find(params[:id], lock: true)
			require_slide_edit(@slide)
  
			if @slide.update_attributes(params[:slide])
        

				#Paistetaan uusi kuva simpleslidelle
				@slide.delay.generate_images if @slide.is_a?(SimpleSlide)
        
				#Haetaan uusi kuva http-slidelle jos on tarvis
				@slide.delay.fetch! if @slide.is_a?(HttpSlide) && @slide.needs_fetch?


				respond_to do |format|
					format.html {
						flash[:notice] = 'Slide was successfully updated.'
						redirect_to :action => 'show', :id => @slide.id and return
					}
					format.js {render :show}
				end
			else
				flash[:error] = "Error updating slide"
				render :action => 'edit' and return
			end
		end
    
	rescue URI::InvalidURIError
		flash[:error] = "Error parsing the slide http url!"
		render :http_edit and return
	end


	private
    
	def require_slide_edit(s)
		#Varmistetaan oikeudet
		unless s.can_edit? current_user
			raise ApplicationController::PermissionDenied
		end
	end
  
	def require_create
		unless Slide.can_create? current_user
			raise ApplicationController::PermissionDenied
		end
	end
  
	def require_admin
		unless Slide.admin? current_user
			raise ApplicationController::PermissionDenied
		end
	end
  
end
