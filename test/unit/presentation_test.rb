require 'test_helper'

class PresentationTest < ActiveSupport::TestCase
	test 'create presentation' do
		p = Presentation.new
		p.name = "Test presentation"
		assert p.save, "Error saving presentation"
		p.reload
		assert_equal Event.current.id, p.event.id, "Presentation is not in current event"
	end
	
	test 'slide count' do
		p = presentations(:empty)
		assert_equal 0, p.groups.count
		assert_equal 0, p.total_slides, "This presentation should be empty"
		assert_equal 0, p.public_slides.count
		
		p = presentations(:with_slides)
		
		assert_equal 4, p.groups.count
		assert_equal 13, p.total_slides
		assert_equal 13, p.public_slides.count
		
		p = presentations(:with_empty_group)
		
		assert_equal 1, p.groups.count
		assert_equal 0, p.total_slides
		assert_equal 0, p.public_slides.count
		
		p = presentations(:with_hidden_slides)
		
		assert_equal 2, p.groups.count
		assert_equal 2, p.total_slides
		assert_equal 2, p.public_slides.count
		
	end
	
	test "slide order" do
		p = presentations(:with_slides)
		slides = p.public_slides.to_a
		
		assert_equal slides(:slide_1), slides[0]
		assert_equal slides(:slide_11), slides[1]
		assert_equal slides(:slide_5), slides[5]
		assert_equal slides(:slide_1), slides[11]
		assert_equal slides(:not_ready), slides[12]
	end
	
	test "duration" do
		assert_equal 0, presentations(:empty).duration
		
		assert_equal 13 * 20, presentations(:with_slides).duration
		
		assert_equal 10 * 50 + 10, presentations(:with_special_duration).duration
	end
	
	test "to_hash" do
		p = presentations(:with_slides)
		h = p.to_hash
		
		assert_equal h[:name], p.name
		assert_equal h[:slides].size, p.public_slides.count 
	end
	
end
