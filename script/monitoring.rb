#!/usr/bin/env script/rails runner

# Background process for updating rrd data

Daemons.run_proc('monitoring.rb') do
	ActiveRecord::Base.connection.reconnect!
	puts 'Starting ISK server monitoring process'
	
  monitoring_logger = ActiveSupport::BufferedLogger.new(
     	File.join(Rails.root, "log", "monitoring.log"))
	Rails.logger = monitoring_logger
	ActiveRecord::Base.logger = monitoring_logger
  
	loop do
    sleep(5)
		Monitoring.update_values!
  end
end