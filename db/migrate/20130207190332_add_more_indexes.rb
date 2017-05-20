# frozen_string_literal: true
class AddMoreIndexes < ActiveRecord::Migration
  def change
    add_index :display_counts, :slide_id
    add_index :display_counts, :display_id
    add_index :display_counts, [:display_id, :slide_id]

    add_index :displays, :presentation_id
    add_index :displays, :last_contact_at

    add_index :displays_users, :display_id
    add_index :displays_users, :user_id

    add_index :groups, :presentation_id
    add_index :groups, :master_group_id
    add_index :groups, [:presentation_id, :position]

    add_index :master_groups_users, :master_group_id
    add_index :master_groups_users, :user_id

    add_index :override_queues, [:display_id, :position]
    add_index :override_queues, :slide_id

    add_index :presentations_users, :presentation_id
    add_index :presentations_users, :user_id

    add_index :roles_users, :role_id
    add_index :roles_users, :user_id

    add_index :slides, :replacement_id
    add_index :slides, :master_group_id
    add_index :slides, [:id, :public]
    add_index :slides, [:id, :type]

    add_index :slides_users, :slide_id
    add_index :slides_users, :user_id

    add_index :users, :username, unique: true
  end
end
