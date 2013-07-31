class GroupsController < ApplicationController
  before_filter :require_create, :only => [:new, :create]
  before_filter :require_admin, :only => [:publish_all, :hide_all]
  
  cache_sweeper :group_sweeper
  
  
  def index
    @groups = MasterGroup.current.defined_groups.all
    @new_group = MasterGroup.new
  end
  
  def show
    @group = MasterGroup.find(params[:id])
  end
  
  def edit
    @group = MasterGroup.find(params[:id])
    require_edit @group
  end
  
  def update
    @group =MasterGroup.find(params[:id])
    require_edit @group
    
    if @group.update_attributes(params[:master_group])
      flash[:notice] = 'Group was successfully updated.'
      redirect_to :action => 'show', :id => @group.id
    else
      render :action => 'edit'
    end
    
  end
  
  #Set all slides in the groups to public
  def publish_all
    @group = MasterGroup.find(params[:id])
    @group.publish_slides
    redirect_to :action => :show, :id => @group.id
  end
  
  #Hide all slides in the group
  def hide_all
    @group = MasterGroup.find(params[:id])
    @group.hide_slides
    redirect_to :action => :show, :id => @group.id
  end
  
  #Change the order of slides in the group, used with jquerry sortable widget.
  def sort
    MasterGroup.transaction do
      group = MasterGroup.find(params[:id])
      require_edit group
      if params[:slide].count == group.slides.count
        MasterGroup.transaction do
          group.slides.each do |slide|
            slide.position = params['slide'].index(slide.id.to_s) + 1
            slide.save
          end
        end
        group.reload
				@group = group
				respond_to do |format|
        	format.js {render :sortable_items}
				end
      else
        render :text => "Invalid slide count, try refreshing", :status => 400
      end
    end
  end

  #Delete a group, all contained slides will become ungrouped
  def destroy
    @group = MasterGroup.find(params[:id])
    require_edit @group
    @group.destroy
    
    redirect_to :action => :index
  end
  
  #Add multiple slides to group, render the selection form for all ungrouped slides
  def add_slides
    @group = MasterGroup.find(params[:id])
    require_edit @group
    
    @slides = Event.current.ungrouped.slides.all
  end
  
  #Add multiple slides to group
  def adopt_slides
    @group = MasterGroup.find(params[:id])
    require_edit @group
    MasterGroup.transaction do 
      params[:slides].each_value do |s|
        if s[:add] == "1"
          s = Slide.current.ungrouped.find(s[:id])
          flash[:notice] = 'Adding slide ' << s.name
          s.master_group_id = @group.id
          s.save!
        end
      end
    end
    
    redirect_to :action => :show, :id => @group.id
  end
  
  def create
    new_group = MasterGroup.new(params[:master_group])
    new_group.event = Event.current
    if new_group.save
      flash[:notice] = "Group created."
      new_group.authorized_users << current_user unless MasterGroup.admin? current_user
    else
      flash[:error] = "Error saving group"
    end
    redirect_to :action => :index
      
  end
  
  def deny
    group = MasterGroup.find(params[:id])
    user = User.find(params[:user_id])
    group.authorized_users.delete(user)
    redirect_to :back
  end
  
  def grant
    group = MasterGroup.find(params[:id])
    user = User.find(params[:grant][:user_id])
    group.authorized_users << user
    redirect_to :back    
  end
  
  #Add all slides on this group to override on a display
  def add_to_override
    group = MasterGroup.find(params[:id])
    display = Display.find(params[:override][:display_id])
    duration = params[:override][:duration].to_i
    
    if display.can_override?(current_user)
      group.slides.each do |s|
        display.add_to_override(s, duration)
      end
      flash[:notice] = "Added group " + group.name + " to override on display " + display.name
    else
      flash[:error] = "You can't add slides to the override queue on display " + display.name
    end
    redirect_to :action => :show, :id => group.id
    
  end
  
  private
  
  def require_create
    raise ApplicationController::PermissionDenied unless MasterGroup.can_create?(current_user)
  end
    
  def require_admin
    raise ApplicationController::PermissionDenied unless MasterGroup.admin?(current_user)
  end
  
end
