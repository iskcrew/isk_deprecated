class AddMissingIndexes < ActiveRecord::Migration
  def change
		add_index :display_states, :display_id
		add_index :display_states, :last_contact_at
		add_index :master_groups, :internal
		add_index :override_queues, :position
		add_index :presentations, :effect_id
		add_index :presentations, :event_id
		add_index :schedules, :event_id
		add_index :schedules, :up_next_group_id
		add_index :schedules, :slidegroup_id
		add_index :slides, :foreign_object_id
		add_index :template_fields, :editable
		
	end
end
