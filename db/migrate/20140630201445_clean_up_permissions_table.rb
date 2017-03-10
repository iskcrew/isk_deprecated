class CleanUpPermissionsTable < ActiveRecord::Migration
  def up
    remove_column :permissions, :master_group_id
    remove_column :permissions, :slide_id
    remove_column :permissions, :role_id
    remove_column :permissions, :display_id
    remove_column :permissions, :presentation_id
  end

  def down
    add_column :permissions, :master_group_id, :integer
    add_column :permissions, :slide_id, :integer
    add_column :permissions, :role_id, :integer
    add_column :permissions, :display_id, :integer
    add_column :permissions, :presentation_id, :integer
  end
end
