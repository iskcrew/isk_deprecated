class LinkEffectToOverrideQueues < ActiveRecord::Migration
  def change
		add_column :override_queues, :effect_id, :integer, default: 1
		add_index :override_queues, :effect_id
	end
end
