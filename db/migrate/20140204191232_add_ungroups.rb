class AddUngroups < ActiveRecord::Migration
	class Event < ActiveRecord::Base
	
	end
	
	class MasterGroup < ActiveRecord::Base
	
	end
	
	
	class UnGroup < MasterGroup
		
	end
	
  def up
		Event.transaction do
			Event.all.each do |e|
				g = MasterGroup.find(e.ungrouped_id)
				g.type = UnGroup.sti_name
				g.save!
			end
		end
  end

  def down
		Event.transaction do
			Event.all.each do |e|
				g = MasterGroup.find(e.ungrouped_id)
				g.type = MasterGroup.sti_name
				g.save!
			end
		end
  end
end
