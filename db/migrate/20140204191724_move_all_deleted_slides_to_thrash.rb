class MoveAllDeletedSlidesToThrash < ActiveRecord::Migration
  def up
		Slide.transaction do
			Slide.where(deleted: true).all.each do |s|
				e = s.master_group.event
				s.master_group = e.thrashed
				s.save!
			end
		end
  end

  def down
  end
end
