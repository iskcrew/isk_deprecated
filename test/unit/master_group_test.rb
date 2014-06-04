require 'test_helper'

class MasterGroupTest < ActiveSupport::TestCase

	test "Create new prize group" do
		data = [{name: 'Fooo', by: 'Me', pts: '3'},{name: 'Bar', by: 'You', pts: '2'}]
		
		pg = PrizeGroup.new(
			name: 'Competition Competition',
			data: data
		)
		
		assert pg.save!
		
		pg = PrizeGroup.find(pg.id)
		
		assert pg.slides.count == 3, "Prizegroup didn't have correct number of slides"
		assert pg.name == 'Competition Competition'
		assert pg.data[0][:name] == 'Fooo'
		assert pg.data[1][:by] == 'You'
		
		pg.slides.each do |s|
			clear_slide_files(s)
		end
	end


end
