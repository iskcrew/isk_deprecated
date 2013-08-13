# ISK - A web controllable slideshow system
#
# General system health monitoring using rrd graphs
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class Monitoring
	
	def self.create_databases
		create_delayed_jobs_rrd unless File.exists? dj_rrd_file
		create_total_slides_rrd unless File.exists? total_slides_rrd_file
	end
	
	def self.update_values!
		update_delayed_jobs_rrd!
		update_total_slides_rrd!
	end
	
	def self.generate_graphs!
		generate_delayed_jobs_graphs
		generate_total_slides_graphs
	end
	
	private

	def self.rrd_path
		rrd_path = Rails.root.join('data', 'rrd')
	end

	def self.dj_rrd_file
		rrd_path.join('delayed_job.rrd').to_s
	end
	
	
	
	def self.total_slides_rrd_file
		rrd_path.join('total_slides.rrd').to_s
	end
	
	def self.create_delayed_jobs_rrd
		delayed_jobs_rrd = RRD::Base.new(dj_rrd_file)
		delayed_jobs_rrd.create :start => Time.now - 10.seconds, :step => 5.minutes do
	  	datasource "queued", :type => :gauge, :heartbeat => 10.minutes, :min => 0, :max => :unlimited
	  	datasource "failed", :type => :counter, :heartbeat => 10.minutes, :min => 0, :max => :unlimited
			archive :average, :every => 5.minutes, :during => 1.year
		end
	end
	
	def self.update_delayed_jobs_rrd!
		delayed_jobs_rrd = RRD::Base.new(dj_rrd_file)
		queued = Delayed::Job.where(:failed_at => nil).count
		failed = Delayed::Job.where('failed_at IS NOT NULL').count
		delayed_jobs_rrd.update! Time.now, queued, failed
	end
	
	def self.generate_delayed_jobs_graphs
		rrd_file = dj_rrd_file
		graphs_array.each do |g|
			RRD.graph! Rails.root.join('data', 'rrd', ('dj_' + g.first + '.png')).to_s, :title => "Delayed jobs (#{g.first})", :width => 800, :height => 250, :start => g.last, :end => Time.now do
				for_rrd_data "queued", :queued => :average, :from => rrd_file
				for_rrd_data "failed", :failed => :average, :from => rrd_file
		  	
				draw_line :data => "queued", :color => '#00FF00', :label => "Queued jobs", :width => 1
				print_value "queued:LAST", :format => 'Current\: %6.2lf %S'
				print_value "queued:AVERAGE", :format => 'Average\: %6.2lf %S'
				print_value "queued:MIN", :format => 'Min\: %6.2lf %S'
				print_value "queued:MAX", :format => 'Max\: %6.2lf %S\n'
				
				draw_line :data => "failed", :color => '#FF0000', :label => "Failed jobs", :width => 1
				print_value "failed:LAST", :format => 'Current\: %6.2lf %S'
				print_value "failed:AVERAGE", :format => 'Average\: %6.2lf %S'
				print_value "failed:MIN", :format => 'Min\: %6.2lf %S'
				print_value "failed:MAX", :format => 'Max\: %6.2lf %S\n'
			end
		end
		
	end
	
	def self.create_total_slides_rrd
		total_slides_rrd = RRD::Base.new(total_slides_rrd_file)
		total_slides_rrd.create :start => Time.now - 10.seconds, :step => 5.minutes do
	  	datasource "shown", :type => :counter, :heartbeat => 10.minutes, :min => 0, :max => :unlimited
			datasource "created", :type => :counter, :heartbeat => 10.minutes, :min => 0, :max => :unlimited
			datasource "thrashed", :type => :counter, :heartbeat => 10.minutes, :min => 0, :max => :unlimited
			archive :average, :every => 5.minutes, :during => 1.year
		end
	end
	
	def self.update_total_slides_rrd!
		total_slides_rrd = RRD::Base.new(total_slides_rrd_file)
		shown = DisplayCount.count
		created = Slide.count
		thrashed = Slide.thrashed.count
		total_slides_rrd.update! Time.now, shown, created, thrashed
	end
	
	def self.generate_total_slides_graphs
		rrd_file = total_slides_rrd_file
		graphs_array.each do |g|
			RRD.graph! Rails.root.join('data', 'rrd', ('slides_' + g.first + '.png')).to_s, :title => "Slides (#{g.first})", :width => 800, :height => 250, :start => g.last, :end => Time.now do
				for_rrd_data "created", :created => :average, :from => rrd_file
				for_rrd_data "shown", :shown => :average, :from => rrd_file
		  	for_rrd_data "thrashed", :thrashed => :average, :from => rrd_file
				
				draw_line :data => "created", :color => '#00FF00', :label => "New slides", :width => 1
				print_value "created:LAST", :format => 'Current\: %6.2lf %S'
				print_value "created:AVERAGE", :format => 'Average\: %6.2lf %S'
				print_value "created:MIN", :format => 'Min\: %6.2lf %S'
				print_value "created:MAX", :format => 'Max\: %6.2lf %S\n'
				
				draw_line :data => "shown", :color => '#0000FF', :label => "Shown slides", :width => 1
				print_value "shown:LAST", :format => 'Current\: %6.2lf %S'
				print_value "shown:AVERAGE", :format => 'Average\: %6.2lf %S'
				print_value "shown:MIN", :format => 'Min\: %6.2lf %S'
				print_value "shown:MAX", :format => 'Max\: %6.2lf %S\n'
				
				draw_line :data => "thrashed", :color => '#FF0000', :label => "Thrashed slides", :width => 1
				print_value "thrashed:LAST", :format => 'Current\: %6.2lf %S'
				print_value "thrashed:AVERAGE", :format => 'Average\: %6.2lf %S'
				print_value "thrashed:MIN", :format => 'Min\: %6.2lf %S'
				print_value "thrashed:MAX", :format => 'Max\: %6.2lf %S\n'
			end
		end
		
	end
	
	
	
	def self.graphs_array
		[
			['24h', Time.now - 1.day], 
			['week', Time.now - 1.week],
			['month', Time.now - 1.month],
			['year', Time.now - 1.year]
		]
	end
	
end