class LinkEffectToMasterGroups < ActiveRecord::Migration
  def change
		add_column :master_groups, :effect_id, :integer
		add_index :master_groups, :effect_id
  end
end
