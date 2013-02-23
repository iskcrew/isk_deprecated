class CurrentSlideSupportForDisplays < ActiveRecord::Migration
  def up
    add_column :displays, :current_group_id, :integer
    add_column :displays, :current_slide_id, :integer
  end

  def down
    remove_column :displays, :current_group_id
    remove_column :displays, :current_slide_id
  end
end
