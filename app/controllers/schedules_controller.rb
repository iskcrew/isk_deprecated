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
    
  end
  
  def edit
    @schedule = Schedule.find(params[:id])
  end
  
  def update
    
  end
  
end
