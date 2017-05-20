# frozen_string_literal: true
class CreateMasterGroupsUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :master_groups_users, id: false do |t|
      t.references :master_group
      t.references :user
    end
  end
end
