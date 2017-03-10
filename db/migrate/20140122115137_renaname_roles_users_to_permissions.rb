class RenanameRolesUsersToPermissions < ActiveRecord::Migration
  def up
    rename_table :roles_users, :permissions
  end

  def down
    rename_table :permissions, :roles_users
  end
end
