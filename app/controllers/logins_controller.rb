class LoginsController < ApplicationController
  skip_before_filter :require_login, :only => [:show, :create]
  
  layout :login_layout
  
  def show
    @user = current_user
  end

  def create
    if user = User.authenticate(params[:username],params[:password])
      reset_session # Protect from session fixation attacks
      session[:user_id] = user.id
      session[:username] = user.username
      flash[:notice] = "Login successfull"
    else
      flash[:error] = "Login invalid"
      raise ApplicationController::PermissionDenied
    end
    redirect_to :controller => :slides, :action => :index
  end
  
  def destroy
    reset_session
    flash[:notice]="User logged out"
    redirect_to :action => :show
  end
  
  private
  
  def login_layout
    current_user ? 'application' : 'not_logged_in'      
  end

end
