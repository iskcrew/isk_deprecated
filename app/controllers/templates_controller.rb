class TemplatesController < ApplicationController
  before_filter :require_template_admin, :except => [:index, :show]
  
  #TODO: Tää pitäs muuttaa toimimaan uusien STI-kelmujen kanssa...
  
  def index
    @templates = SlideTemplate.all
  end
  
  def new
    @template = SlideTemplate.new
  end

  def create
    SlideTemplate.transaction do
      @template = SlideTemplate.new(params[:slide_template])
      if @template.save
       
        case params[:create_type]
        when 'empty_file'
          FileUtils.copy(SlideTemplate::EmptySVG, @template.svg_filename)
       
        when 'upload_file'
          File.open(@template.svg_filename, 'w') do |file|
            file.write params[:slide_template][:upload].read
          end
       
        when 'from_template'
          import_template = SlideTemplate.find(params[:use_template])
          FileUtils.copy(import_template.svg_filename, @template.svg_filename)
        end
       
        flash[:notice] = 'Template was successfully created.'
        redirect_to :action => :index
      else
        render :action => :new
      end
    end
  end
  
  def edit
    @template = SlideTemplate.find(params[:id])
  end
  
  def svg_edit
    @template = SlideTemplate.find(params[:id])
  end
  
  def svg_data
    template = SlideTemplate.find(params[:id])
    send_file template.svg_filename
  end
  
  def svg_save
    @template = SlideTemplate.find(params[:id])
    File.open(@template.svg_filename,  'w') do |f|
      f.write params[:svg]
    end
        
    render :nothing => true
  end
  
  def update
    @template = SlideTemplate.find(params[:id])
    if @template.update_attributes(params[:slide_template])
      flash[:notice] = 'Template was successfully updated.'
      redirect_to :action => :index
    else
      render :action => :edit
    end
  end
  
  private

  def require_template_admin
    unless require_role('template-admin')
      raise ApplicationController::PermissionDenied
    end
  end
  
  
end
