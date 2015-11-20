require 'test_helper'
require 'redis_test_helpers'

class SlideTest < ActiveSupport::TestCase
	include RedisTestHelpers
	
	def setup
		Slide.send(:remove_const, :FilePath)
		Slide.const_set(:FilePath, Rails.root.join('tmp','test'))
		
		@testpattern_1080p = Rails.root.join('test', 'assets', 'testpattern_1080p.png').to_s
		@svg_scaling_test = Rails.root.join('test', 'assets', 'scaling_test.svg').to_s
	end
	
	def teardown
		Slide.all.each do |s|
			clear_slide_files(s)
		end
	end
	
	test "STI inheritance selectors" do
		assert	SvgSlide.count == 3, "Should have 3 slides inheriting from SvgSlide"
	end
	
	test "imageslide scaling" do
		slide = ImageSlide.new(name: 'Scaling test')
		slide.image = File.open(@testpattern_1080p)
		slide.save!
		slide.generate_images
		
		command = "compare #{@testpattern_1080p} #{slide.full_filename} /dev/null"
		assert system(command), "Image differs after imageslide processing"
	end
	
	test "Inkscape slide background image scaling" do
		slide = InkscapeSlide.new(name: 'Scaling test')
		slide.svg_data = File.read(@svg_scaling_test)
		slide.save!
		slide.generate_images
		
		command = "compare #{@testpattern_1080p} #{slide.full_filename} /dev/null"
		assert system(command), "Image differs after inkscape slide processing"
	end
	
	test "simple slide update without modifying slidedata" do
		init_slide_files slides(:simple)
		slide = Slide.find(slides(:simple).id)
		slide.name = 'Updated'
		assert slide.save
		assert slide.reload
		assert slide.ready, "Slidedata updater marked slide as not ready when slidedata didn't change!"
	end
	
	test "simple slide creation" do
		with_redis do
			slide = SimpleSlide.new(name: 'test slide')
			slide.slidedata = {header: 'test slide'}
			assert slide.save
			assert_not slide.ready
		end
		assert_equal 1,redis_messages.count, "Creating new slide should send one websocket notification"
		msg = IskMessage.from_json(redis_messages.first)
		assert_equal 'slide', msg.object, "The message should be about slides"
		assert_equal 'create', msg.type, "Message should be of type create"
	end
	
	test "simple slide slidedata update" do
		init_slide_files slides(:simple)
		slide = Slide.find(slides(:simple).id)
		slide.slidedata = {header: 'updated header'}
		assert slide.save
		assert slide.reload
		assert_not slide.ready, "Slide is marked as ready even after changing the svg data."
	end
end
