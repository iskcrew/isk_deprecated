require 'test_helper'

class DisplayTest < ActiveSupport::TestCase
  test "hello on existing display" do
		d = Display.hello 'Normal', '127.0.0.1'
		
		assert_equal d.id, displays(:normal).id, "Got wrong display"
		
	end
	
	test "hello on new display" do
		d = Display.hello "Hi, I'm new", "127.0.0.1"
		
		assert_equal 1, Display.where(name: "Hi, I'm new").count, "Display not found in db"
	end
	
	test "set current slide" do
		d = displays(:normal)
		d.set_current_slide 3, 1
		
		assert_equal 3, d.current_group_id, "Wrong group"
		assert_equal 1, d.current_slide_id, "Wrong slide"
		assert_equal 1, DisplayCount.where(display_id: d.id, slide_id: 1).count
	end
	
	test "show override" do
		d = displays(:with_overrides)
		assert_equal 3, d.override_queues.count, "Test setup should have 3 slides in queue"
		
		d.override_shown 1
		
		assert_equal 2, d.override_queues.count, "Slide wasn't removed from queue"
		assert_equal 1, DisplayCount.where(:display_id => d.id).count, "Should mark the slide as shown"
	end
	
	test "select late displays" do
		assert_equal 1, Display.late.count, "Test database should have one late display"
		
		d = displays(:no_presentation)
		d.monitor = true
		d.save!
		
		assert_equal 2, Display.late.count, "Switching a unmonitored late display to monitored"		
	end
	
	test "add slide to override" do
		d = displays(:normal)
		assert_equal 0, d.override_queues.count
		
		s = slides(:slide_1)
		d.add_to_override s, 60
		
		assert_equal 1, d.override_queues.count
		assert_equal 60, d.override_queues.first!.duration
		assert_equal s.id, d.override_queues.first!.slide_id
		
	end
	
	test "late?" do
		assert displays(:late).late?
		assert !displays(:normal).late?
	end
	
	test "to_hash" do
		h = displays(:normal).to_hash
		assert h[:id] = displays(:normal).id, "Hash had wrong display id"
		assert h[:presentation][:name] = "I have 1+10+1+1 slides!", "Hash had wrong presentation name"
		
		h = displays(:no_presentation).to_hash
		assert h[:id] = displays(:no_presentation).id, "Hash had wrong display id"
		assert h[:presentation].empty?, "Hash contained a presentation"
		
	end

	
end
