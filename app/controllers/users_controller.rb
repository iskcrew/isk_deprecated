# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class UsersController < ApplicationController

  before_filter :require_global_admin

  def index
    @users = User.order(:username).all
  end

  def roles
    @user = User.find(params[:id])
    @roles = Role.order('role').all
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
    @user=User.find(params[:id])
  end

  def update
    @user=User.find(params[:id])
    unless params[:password][:password].empty? then
      if params[:password][:password] == params[:password][:verify] then
        @user.password=params[:password][:password]
      else
        @user.errors.add('', "Passwords don't match")
        render :action => 'edit'
        return
      end
    end
    if @user.save
      flash[:notice]="User updated"
      redirect_to :action => :index
    else
      render :action=>:edit
    end
	end

end
