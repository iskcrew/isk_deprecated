#ISK server background jobs
require 'rubygems'
require 'daemon'


puts 'Starting ISK server background process'

Daemon.daemonize(Rails.root.join('tmp','pids','background_jobs.pid'),Rails.root.join('log', 'background_jobs.log'))

puts Time.now.to_s + " Daemon started"

ActiveRecord::Base.connection.reconnect!
loop do
	#Import assemblytv schedule
	Schedule.where(:name => 'AssemblyTV').each do |schedule|
		begin
			xml = REXML::Document.new(Net::HTTP.get(URI.parse('http://elaine.aketzu.net/channels/9/playlist/schedule.xml')))
			xml.root.elements.each('//entry') do |entry|
			event = schedule.schedule_events.where(:external_id => entry.attributes['id']).first_or_initialize
			event.name =e ntry.elements.to_a('title[@lang="en"]').first.text
			event.at = Time.parse(entry.elements.to_a('start_at').first.text)
			event.save!
		end
		
			#Remove cancelled programs
			schedule.schedule_events.each do |event|
				event.delete if xml.root.elements.to_a('entry[@id="'+event.external_id+'"]').blank?
			end
		
		rescue
			#HTTP timeout, retry next time
		end
	end
	
	#Fetch barro-schedule and update schedules based on it (major events)
	Schedule.where(:name => 'Major events').each do |schedule|
		begin
			barro_data = Net::HTTP.get(URI.parse('http://schedule.assembly.org/asms13/schedules/events.json'))
			json = JSON.parse(barro_data)
			json["events"].each do |entry|
				if entry['flags'].include?('major') or entry['flags'].include?('bigscreen')
					event = schedule.schedule_events.where(:external_id => entry['key']).first_or_initialize
					event.name = entry['name'].strip
					event.at = Time.parse(entry['start_time'])
					event.save!
					event.delete if entry['flags'].include?('cancelled')
				end
			end
		
		rescue 
		
		end
	end
	
	#Fetch barro-schedule and update schedules based on it (seminars)
	Schedule.where(:name => 'ARTtech Seminars').each do |schedule|
		begin
			barro_data = Net::HTTP.get(URI.parse('http://schedule.assembly.org/asms13/schedules/events.json'))
			json = JSON.parse(barro_data)
			json["events"].each do |entry|
				if entry['categories'].include?('Seminar')
					event = schedule.schedule_events.where(:external_id => entry['key']).first_or_initialize
					event.name = entry['name'].split('ARTtech seminars:').last.strip
					event.at = Time.parse(entry['start_time'])
					event.save!
					event.delete if entry['flags'].include?('cancelled')
				end
			end
		
		rescue 
		
		end
	end
	
	HttpSlide.all.each do |slide|
		slide.delay.fetch!
	end
	Schedule.all.each do |schedule|
		schedule.generate_slides
	end
	
	sleep(180)
end
