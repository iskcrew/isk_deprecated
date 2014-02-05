class MoveAllDeletedSlidesToThrash < ActiveRecord::Migration
	class Slide < ActiveRecord::Base
	
	end
	
	
	
  def up
		sql = 'UPDATE slides JOIN master_groups ON slides.master_group_id = master_groups.id JOIN events ON master_groups.event_id = events.id SET slides.master_group_id = events.thrashed_id WHERE slides.deleted = 1;'
		connection = ActiveRecord::Base.connection
		connection.transaction do
			connection.execute(sql)
		end
  end

  def down
  end
end
