class SchedulesController < ApplicationController
  def index
    @schedules = Schedule.all
  end
  
  def show
    @schedule = Schedule.find(params[:id])
  end
  
  def new
    @schedule = Schedule.new
  end
  
  def create
    @schedule = Schedule.new(params[:schedule])
    if @schedule.save
      flash[:notice] = "Schedule created"
    else
      flash[:error] = "Error creating schedule"
      render :edit and return
    end
  end
  
  def edit
    @schedule = Schedule.find(params[:id])
  end
  
  def update
    
  end
  
end
