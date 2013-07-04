class PresentationsController < ApplicationController
  before_filter :require_create, :only => [:new, :create]
  
  def index
    @presentations = Presentation.all
  end
      
  def show
    @presentation = Presentation.find(params[:id])
    
    respond_to do |format|
      format.html
      format.json {render :json =>JSON.pretty_generate(@presentation.to_hash)}
      
    end
  end
  
  def sort
    p = Presentation.find(params[:id])
    require_edit p
    
    if params[:group].count == p.groups.count
      Presentation.transaction do
        p.groups.each do |g|
          g.position = params[:group].index(g.id.to_s) + 1
          g.save
        end
      end
      p.reload
      render :partial => 'group_items', :locals => {:presentation => p}
    else
      render :text => "Invalid group count, try refreshing", :status => 400
    end
    
  end
  
  def add_to_override
    presentation = Presentation.find(params[:id])
    display = Display.find(params[:override][:display_id])
    duration = params[:override][:duration].to_i
    
    if display.can_override?(current_user)
      presentation.slides.each do |s|
        display.add_to_override(s, duration)
      end
      flash[:notice] = "Added presentation " + presentation.name + " to override on display " + display.name
    else
      flash[:error] = "You can't add slides to the override queue on display " + display.name
    end
    redirect_to :action => :show, :id => presentation.id
    
  end
  
  def add_group
    Presentation.transaction do
      @presentation = Presentation.find(params[:id])
      require_edit @presentation
      
      g = @presentation.groups.new
      g.master_group_id = params[:group][:id]
      @presentation.groups << g
      g.save!
      flash[:notice] = "Added group " + g.name + " to presentation"
      redirect_to :back
    end
  end
  
  def remove_group
    g = Group.find(params[:id])
    p = g.presentation
    require_edit p
    
    g.destroy
    flash[:notice] = "Removed group " + g.name + " from presentation"
    redirect_to :back
  end
  
  def next_slide
    p = Presentation.find(params[:id])
    next_slide = p.next_slide(params[:group], params[:slide])
    
    render :text => p.id.to_s + '/' + next_slide[0].to_s + "/" + next_slide[1].to_s
  end
  
  def slide
    p = Presentation.find(params[:id])
    s = p.slide(params[:group], params[:slide])
    render :text => url_for( :controller => :slides, :action => :full, :id => s.id)
  end
  
  def preview
    @presentation = Presentation.find(params[:id])
  end
    
  def new
    @presentation = Presentation.new
  end
  
  def create
    @presentation = Presentation.new(params[:presentation])
    if @presentation.save
      @presentation.authorized_users << current_user unless Presentation.admin?(current_user)
      flash[:notice] = 'Presentation was successfully created.'
      redirect_to :action => :show, :id => @presentation.id
    else
      render :action => :new
    end  
  end
    
  def edit
    @presentation = Presentation.find(params[:id])
    require_edit @presentation
    
    @orphan_groups = MasterGroup.joins('LEFT OUTER JOIN groups on master_groups.id = groups.master_group_id').where('(groups.presentation_id AND master_groups.id <> 1) IS NULL OR (groups.presentation_id <> ? )', params[:id]).uniq.all
  end  
    
  def update
    @presentation =Presentation.find(params[:id])
    require_edit @presentation
    
    if @presentation.update_attributes(params[:presentation])
      flash[:notice] = 'Presentation was successfully updated.'
      redirect_to :action => 'show', :id => @presentation.id
    else
      render :action => 'edit'
    end
  end
  
  def deny
    presentation = Presentation.find(params[:id])
    user = User.find(params[:user_id])
    presentation.authorized_users.delete(user)
    redirect_to :back
  end
  
  def grant
    presentation = Presentation.find(params[:id])
    user = User.find(params[:grant][:user_id])
    presentation.authorized_users << user
    redirect_to :back    
  end
  
  
  private
  
  def require_admin
    raise ApplicationController::PermissionDenied unless Presentation.admin? current_user
  end
  
  def require_create
    raise ApplicationController::PermissionDenied unless Presentation.can_create? current_user
  end
    
end
