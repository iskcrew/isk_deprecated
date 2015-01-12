require 'simplecov'
SimpleCov.start 'rails'

require 'minitest/reporters'
reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]


ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Copy over placeover slide datafiles for testing purposes
	def init_slide_files(slide)
		imagefile = Rails.root.join('test', 'assets','image.png').to_s
		svgfile = Rails.root.join('test', 'assets', 'slide.svg').to_s
		
		images = Array.new
		
		images << slide.full_filename.to_s
		images << slide.preview_filename.to_s
		images << slide.thumb_filename.to_s
		
		if slide.is_a?(ImageSlide) || slide.is_a?(HttpSlide)
			images << slide.original_filename.to_s
		end
		
		images.each do |i|
			FileUtils.cp imagefile, i
			FileUtils.chmod 0600, i
		end
		
		if slide.respond_to? :svg_filename
			FileUtils.cp  svgfile, slide.svg_filename.to_s
			FileUtils.chmod 0600, slide.svg_filename.to_s
		end
		
	end
	
	
	# During testing we will end up generating slide datafiles in a temporary location.
	# This method will clear any such files out and is generally called on teardown in tests
	# involving slides.
	def clear_slide_files(s)
		['.svg', '_full.png', '_preview.png', '_thumb.png', '_data', '_original'].each do |t|
			f = Rails.root.join('tmp','test', "slide_#{s.id.to_s + t}")
			if File.exists? f
				Rails.logger.info "Deleting temporary slide datafile: #{f.to_s}"
				File.delete f
			end
		end
	end
	
	def assert_actions_denied(actions, session = nil, to_login = true)
		actions.each_key do |verb|
			actions[verb].each do |action|
				send verb, action.first, action.last, session
				if to_login
					assert_redirected_to login_path, "#{verb}: #{action.first} didn't redirect to login page"
				else
					assert_response 403, "#{verb}: #{action.first} didn't return 403 Forbidden"
				end
			end
		end
	end
	
	def assert_acl_coverage(c, tested_actions, allowed = {})
		actions = get_controller_routes(c.to_s)
		count = 0
		actions.each_value {|v| count =+ v.size}
		
		assert count > 0, "No actions were found for controller #{c.to_s}, typo?"
		
		missed = []
		actions.each_key do |verb|
			tested = tested_actions[verb].collect {|x| x.first}
			actions[verb].each do |a|
				unless tested.include?(a.to_sym) || (allowed[verb] && allowed[verb].include?(a.to_sym))
					missed << "#{verb.upcase} :#{a}"
				end
			end
		end
		
		assert missed.empty?, "Following actions were missed in ACL tests: \n#{missed.join "\n"}"
	end
	
	def get_controller_routes(c)
		routes = {
			get: [],
			post: [],
			put: [],
			patch: [],
			delete: []
		}
		
		Rails.application.routes.routes.each do |r|
			req = r.requirements
			if req[:controller] == c
				verb = %W{ GET POST PUT PATCH DELETE }.grep(r.verb).first.downcase.to_sym
				routes[verb] << req[:action]
			end
		end
		return routes
	end
	
end
