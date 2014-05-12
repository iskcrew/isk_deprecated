require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
	
	def clear_slide_files(s)
		['.svg', '_full.png', '_preview.png', '_thumb.png', '_data', '_original'].each do |t|
			f = Rails.root.join('tmp','test', "slide_#{s.id.to_s + t}")
			if File.exists? f
				Rails.logger.info "Deleting temporary slide datafile: #{f.to_s}"
				File.delete f
			end
		end
	end
	
end
