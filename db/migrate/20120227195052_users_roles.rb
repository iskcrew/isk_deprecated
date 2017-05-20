# frozen_string_literal: true
class UsersRoles < ActiveRecord::Migration
  def up
    create_table :roles_users, id: false do |t|
      t.integer "role_id"
      t.integer "user_id"
    end
  end

  def down
    drop_table :roles_users
  end
end
