class GroupsController < ApplicationController
  before_filter :require_create, :only => [:new, :create]
  before_filter :require_admin, :only => [:publish_all, :hide_all]
  
  cache_sweeper :group_sweeper
  
  
  def index
    @groups = MasterGroup.defined_groups.all
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
  
  def publish_all
    @group = MasterGroup.find(params[:id])
    @group.publish_slides
    redirect_to :action => :show, :id => @group.id
  end
  
  def hide_all
    @group = MasterGroup.find(params[:id])
    @group.hide_slides
    redirect_to :action => :show, :id => @group.id
  end
  
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
        render :partial => 'slide_items', :locals => {:group => group}
      else
        render :text => "Invalid slide count, try refreshing", :status => 400
      end
    end
  end

  def destroy
    @group = MasterGroup.find(params[:id])
    require_edit @group
    @group.destroy
    
    redirect_to :back
  end
  
  def add_slides
    @group = MasterGroup.find(params[:id])
    require_edit @group
    
    @slides = Slide.current.ungrouped
  end
  
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
    new_group.event_id = 2 #PURKKAA
    if new_group.save
      flash[:notice] = "Group created."
      new_group.authorized_users << current_user unless current_user.has_role?(MasterGroup::AdminRole)
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
  
  
  private
  
  def require_create
    raise ApplicationController::PermissionDenied unless require_role('group-admin') || require_role('group-create')
  end
    
  def require_admin
    raise ApplicationController::PermissionDenied unless require_role 'group-admin'
  end
  
end
