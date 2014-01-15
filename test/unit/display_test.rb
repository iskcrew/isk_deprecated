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
end
