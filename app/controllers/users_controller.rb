class UsersController < ApplicationController

  before_filter :require_admin

  def index
    @users = User.all
  end

  def roles
    @user = User.find(params[:id])
    @roles = Role.all
  end

  #Grant roles to a user
  def grant
    user=User.find(params[:id])
    params[:roles].each_pair do |role_id, checked|
      r = Role.find(role_id)
      if checked.to_i == 1
        unless user.roles.include?(r)
          user.roles << r
        end

      else
        if user.roles.include?(r)
          user.roles.delete(r)
        end
      end
    end
    user.save!
    flash[:notice] = "User roles changed"
    redirect_to :action=>'index'

  end

  def list
    @users = User.find(:all)
  end

  def new
    @edituser=User.new
  end

  def create
    User.transaction do 
      @user=User.new
      @user.username = params[:user][:username]
      if params[:password][:password] == params[:password][:verify] then
        @user.password=params[:password][:password]
        if @user.save then
          flash[:notice]="User created"
          redirect_to :controller=>"users",:action=>"index"
        else
          render :action=>"new"
        end
      else
        flash[:error]="Passwords don't match"
        @edituser.errors.add "Passwords don't match",""
        render :action=>"new"
      end

    end
  end

  def show
    @user=User.find(params[:id])
  end

  def edit
    @edituser=User.find(params[:id])
  end

  def update
    @edituser=User.find(params[:id])
    @edituser.attributes=params[:user]
    unless params[:password][:password].empty? then
      if params[:password][:password] == params[:password][:verify] then
        @edituser.password=params[:password][:password]
      else
        @edituser.errors.add('', "Passwords don't match")
        render :action => 'edit'
        return
      end
    end
    if @edituser.save
      flash[:notice]="User updated"
      redirect_to :action => 'list'
    else
      render :action=>"edit"
    end
  end

  private

  def require_admin
    unless current_user.has_role?('admin')
      raise ApplicationController::PermissionDenied
    end
  end


end
