class SlidesController < ApplicationController    
  before_filter :require_create, :only => [:new, :create]
  before_filter :require_admin, :only => [:deny, :grant, :to_inkscape]
  skip_before_filter :require_login, :only => [:svg_save, :preview, :full]
  
  
  def index
    if params[:filter] == 'edit'
      @slides = Slide.can_edit(current_user).all
      @filter = :edit
    elsif params[:filter] == 'hide'
      if current_user.has_role?('slide-hide')
        @slides = Slide.current.public
      else
        @slides = Slide.can_edit(current_user).all
      end
      @filter = :hide
    else
      @groups = Array.new
      @groups << MasterGroup.ungrouped
      @groups << MasterGroup.defined_groups.order("LOWER(name), name").includes(:slides).all
      @groups.flatten!
    end
    
    respond_to do |format|
      format.js
      format.html
    end
  end

  def deny
    slide = Slide.find(params[:id])
    user = User.find(params[:user_id])
    slide.authorized_users.delete(user)
    redirect_to :back
  end
  
  def grant
    slide = Slide.find(params[:id])
    user = User.find(params[:grant][:user_id])
    slide.authorized_users << user
    redirect_to :back    
  end

  def add_to_group
    slide = Slide.current.ungrouped.find(params[:id])
    require_edit(slide)
    
    group = MasterGroup.defined_groups.find(params[:add_to_group][:group_id])
    require_edit(group)
    
    group.slides << slide
    
    flash[:notice] = "Added slide " << slide.name << " to group " << group.name
    
    redirect_to :back
  end
  
  def add_to_override
    slide = Slide.current.find(params[:id])
    require_edit(slide)
    
    display = Display.find(params[:add_to_override][:display_id])
    require_edit(display)
    
    Display.transaction do
      oq = display.override_queues.new
      oq.duration = params[:add_to_override][:duration].to_i
      oq.slide = slide
      oq.save!
    end
    flash[:notice] = 'Added slide ' << slide.name << ' to override queue for display ' << display.name
    
    redirect_to :back
  end

  def toggle_clock
    @slide = Slide.find(params[:id])
    require_slide_edit(@slide)
    
    @slide.show_clock = @slide.show_clock ? false : true
    @slide.save!
    
    respond_to do |format|
      format.js {render :show}
      format.html {redirect_to :back}
    end
  end

  def hidden
    @slides = Slide.current.hidden.all
  end


  def hide
    @slide = Slide.find(params[:id])
    
    unless @slide.can_hide? current_user
      flash[:error] = "Not allowed"
      redirect_to :back and return
    end
    
    @slide.public = false
    if authorize != 'isk' && @slide.grouped?
      redirect_to :back 
      return
    end
    
    @slide.save!

    respond_to do |format|
        format.html {redirect_to :back}
        format.js {render :show}
    end
  end
    
  def publish
    @slide = Slide.find(params[:id])
    require_slide_edit @slide
    
    @slide.public = true
    @slide.save!
    
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
    end
    
    unless @slide.is_a? SvgSlide
      flash[:error] = "This slide isn't SVG-Editor slide, you cannot edit it online!"
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
    @slide = Slide.find(params[:id])

    @slide.svg_data= params[:svg]

    @slide.delay.generate_images
    
    render :nothing => true
  end

  def to_inkscape
    slide = SvgSlide.find(params[:id])
    ink = InkscapeSlide.copy! slide
    
    flash[:notice] = "Slide was converted to inkscape slide"
    redirect_to :action => :show, :id => ink.id
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
    
    unless current_user.has_role? 'slide-admin'
      #sallitaan vain yksinkertaisten ryhmättömien kelmujen luonti
      render :new_simple
      return
    end
    
  end
  
  def destroy
    @slide = Slide.find(params[:id])
    require_slide_edit @slide
    
    Slide.transaction do
      @slide.destroy
      @slide.save!
    end
    redirect_to :action => :show, :id => @slide.id
  end
  
  def undelete
    @slide = Slide.find(params[:id])
    
    require_slide_edit(@slide)
    
    Slide.transaction do
      @slide.undelete
      @slide.save!
    end
    
    redirect_to :action => :show, :id => @slide.id
  end
  
  def replace
    @slide = Slide.find(params[:id])
    @slides = Slide.current.ungrouped
  end
  
  def replace_slide
    @slide = Slide.find(params[:id])
    
    require_slide_edit(@slide)
    
    replacement = Slide.current.ungrouped.find(params[:slide][:replacement_id])
    Slide.transaction do
      @slide.replacement = replacement
      @slide.save!
    end
    
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
        @slide = Slide.new
        @slide.name = params[:slide][:name]

        unless @slide.save
          render :action => :new
          return
        end

        if require_role 'slide-admin'
          @slide.master_group = MasterGroup.find(params[:slide][:master_group_id])
        else
          @slide.master_group_id = MasterGroup::Ungrouped_id
          params[:create_type] = 'simple'
        end
        
        
        case params[:create_type]
        when 'upload_file'
          slide_picture_io = params[:slide][:upload]

          File.open(@slide.original_filename.to_s, 'w') do |file|
            file.write(slide_picture_io.read)
          end

          #test that the image is valid for rmagick
          Magick::ImageList.new(@slide.original_filename.to_s)
      
          @slide.delay.generate_images
      
        when 'empty_file'
          FileUtils.copy(InkscapeSlide::EmptySVG, @slide.svg_filename)
          @slide.is_svg = true
          @slide.type = InkscapeSlide.sti_name
          @slide.save!
          @slide = Slide.find(@slide.id) #muuten delayed job kusee
          @slide.delay.generate_images
        when 'from_template'
          import_template = SlideTemplate.find(params[:use_template])
          FileUtils.copy(import_template.svg_filename, @slide.svg_filename)
          @slide.type = SvgSlide.sti_name
          @slide.is_svg = true
          @slide.save!
          @slide = Slide.find(@slide.id) #muuten delayed job kusee
          @slide.delay.generate_images
        when 'simple'
          FileUtils.copy(SlideTemplate::SimpleSVG, @slide.svg_filename)
          @slide.type = SimpleSlide.sti_name
          @slide.is_svg = true
          @slide.save!


          @slide = Slide.find(@slide.id) #muuten loput kusee koska operoidaan väärällä luokalla
          
          
          slidedata = {:heading => params[:head], :text => params[:text], 
            :text_size => params[:text_size], :color => params[:color], 
            :text_align => params[:text_align]}
        
          @slide.slidedata = slidedata
          
          @slide.svg_data = params[:code] if params[:code]
          
          @slide.delay.generate_images
        when 'http_slide'
          @slide.type = HttpSlide.sti_name
          @slide.save!
          @slide = Slide.find(@slide.id) #jotta kelmu olisi oikeaa aliluokkaa
          
          begin
            URI::parse params[:url]
          rescue URI::InvalidURIError
            flash[:error] = "Error parsing the slide http url!"
            render :http_edit and return
          end

          slidedata = {:url => params[:url], :user => params[:basic_username], :password => params[:basic_password]}

          @slide.slidedata = slidedata
          @slide.ready = false
          @slide.save!
          @slide.delay.fetch!
          
        else
          raise ArgumentError 'Invalid slide type requested'

        end
        
        unless @slide.can_edit? current_user
          @slide.authorized_users << current_user
        end
        
        
      end #transaktio
      
      @slide = Slide.find(@slide.id)
      
      if @slide.type == SvgSlide.model_name
        redirect_to :action => :svg_edit, :id => @slide.id
      else
        redirect_to :action => :show, :id => @slide.id
      end 
    
    rescue Magick::ImageMagickError
      #image invalid
      File::delete(@slide.original_filename)
      flash[:error] = "Error creating slide, invalid image file"
      render :action => :new
    end
    
  end
  
  #TODO ajax!
  def ungroup
    Slide.transaction do
      slide = Slide.find(params[:id])
      require_edit(slide)
      slide.master_group_id = 1
      slide.save!
    end

    respond_to do |format|
      format.html {redirect_to :back}
      format.js {render :index}
    end
  end
  
  def preview
    @slide = Slide.find(params[:id])
    
    respond_to do |format|
    format.html {
      if @slide.ready
        send_file(@slide.preview_filename, {:disposition => 'inline'})
      else
        send_file(Rails.root.join('public','no_image.jpg'), {:disposition => 'inline'})
      end
      }
      format.js {render :show}
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
        render :nothing => true, :status => 404
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
    @slide =Slide.find(params[:id])
    
    require_slide_edit(@slide)
    
    if @slide.update_attributes(params[:slide])      
      case @slide.type
      when SimpleSlide.sti_name
        slidedata = {:heading => params[:head], :text => params[:text], 
          :text_size => params[:text_size], :color => params[:color], 
          :text_align => params[:text_align]}
        @slide.slidedata = slidedata
        
        @slide.svg_data = params[:code]
        
        @slide.save!
        @slide.delay.generate_images
        
      when HttpSlide.sti_name
        begin
          URI::parse params[:url]
        rescue URI::InvalidURIError
          flash[:error] = "Error parsing the slide http url!"
          render :http_edit and return
        end
        
        slidedata = {:url => params[:url], :user => params[:basic_user], :password => params[:basic_password]}
        
        @slide.slidedata = slidedata
        @slide.ready = false
        @slide.save!
        @slide.delay.fetch!
      end
      
      flash[:notice] = 'Slide was successfully updated.'
      
      redirect_to :action => 'show', :id => @slide.id and return
    else
      flash[:error] = "Error updating slide"
      render :action => 'edit'
    end
  end
  
  private
  
  def require_slide_edit(s)
    #Varmistetaan oikeudet
    unless s.can_edit? current_user
      raise ApplicationController::PermissionDenied
    end
  end
  
  def require_create
    unless require_role('slide-create') || require_role('slide-admin')
      raise ApplicationController::PermissionDenied
    end
  end
  
  def require_admin
    unless current_user.has_role?('slide-admin')
      raise ApplicationController::PermissionDenied
    end
  end
  
end
