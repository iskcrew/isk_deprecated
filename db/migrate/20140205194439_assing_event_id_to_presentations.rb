class AssingEventIdToPresentations < ActiveRecord::Migration
  # Assign all presentations to the event where their component groups belong
	def up
		sql = "update presentations join groups on presentations.id = groups.presentation_id join master_groups on groups.master_group_id = master_groups.id set presentations.event_id = master_groups.event_id;"
		connection = ActiveRecord::Base.connection
		connection.transaction do
			connection.execute(sql)
		end
  end

  def down
  end
end
