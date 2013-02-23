class ImagesController < ApplicationController

  before_filter :require_image_admin, :except => [:index, :preview, :full, :imagelib]

  def index
    @images = Image.order('name ASC')
  end

  def imagelib
    @images = Image.order('name ASC')
    render :layout => false
  end

  def destroy
    @image = Image.find(params[:id])
    @image.destroy
    flash[:notice] = "Image deleted"
    redirect_to :back
  end
  
  def edit
    @image = Image.find(params[:id])
  end
  
  def update
    @image = Image.find(params[:id])
    if @image.update_attributes(params[:image])
      flash[:notice] = 'Image was successfully updated.'
      redirect_to :action => :index
    else
      render :action => 'edit'
    end
  end
  


  def new
    @image = Image.new
  end
  
  def create
    begin
      #transaktiona jotta kantaan ei mene mitään jos tiedostosta ei saada kuvaa ulos
      Slide.transaction do
        @image = Image.new
        @image.name = params[:image][:name]

        #tallennetaan jotta saadaan id
        @image.save!
        @image.filename = "image_" + @image.id.to_s
        @image.save!
      
      
        picture_io = params[:image][:upload]
    
        File.open(@image.original_filename, 'w') do |file|
          file.write(picture_io.read)
        end
      
        #test that the image is valid for rmagick
      
        Magick::ImageList.new(@image.original_filename)
      
        @image.delay.generate_images
        
      end
      redirect_to :action => :index
    
    rescue Magick::ImageMagickError
      #image invalid
      File::delete(Rails.root.join('slides', @slide.filename + '_orginal'))
      flash[:error] = "Error creating slide, invalid image file"
      render :action => :new
    end
    
    
  end

  def preview
    image = Image.find(params[:id])
    if File.exists?(image.preview_filename)
      send_file(image.preview_filename, {:disposition => 'inline'})
    else
      send_file(Rails.root.join('public','no_image.png'), {:disposition => 'inline'})
    end
  end

  def full
    image = Image.find(params[:id])
    if File.exists?(image.full_filename)
      send_file(image.full_filename, {:disposition => 'inline'})
    else
      send_file(Rails.root.join('public','no_image.png'), {:disposition => 'inline'})
    end
  end
  
  private
  
  def require_image_admin
    raise ApplicationController::PermissionDenied unless require_role('image-admin')
  end


end
