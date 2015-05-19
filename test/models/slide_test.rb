require 'test_helper'

class SlideTest < ActiveSupport::TestCase
	test "Test STI inheritance selectors" do
		assert	SvgSlide.count == 3, "Should have 3 slides inheriting from SvgSlide"
	end
end
