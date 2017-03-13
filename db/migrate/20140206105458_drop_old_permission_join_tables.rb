class DropOldPermissionJoinTables < ActiveRecord::Migration
  def up
    connection = ActiveRecord::Base.connection
    connection.transaction do
      drop_table :displays_users
      drop_table :master_groups_users
      drop_table :presentations_users
      drop_table :slides_users
    end
  end

  def down
    create_table "displays_users", id: false do |t|
      t.integer "display_id"
      t.integer "user_id"
    end

    create_table "master_groups_users", id: false do |t|
      t.integer "master_group_id"
      t.integer "user_id"
    end

    create_table "presentations_users", id: false do |t|
      t.integer "presentation_id"
      t.integer "user_id"
    end

    create_table "slides_users", id: false, force: true do |t|
      t.integer "slide_id"
      t.integer "user_id"
    end
  end
end
