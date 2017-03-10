class MoveOldJoinTablesToPermissions < ActiveRecord::Migration
  def up
    connection = ActiveRecord::Base.connection
    connection.transaction do
      slides_users_sql = "SELECT user_id, slide_id FROM slides_users;"
      connection.execute(slides_users_sql).each do |r|
        Permission.create(user_id: r.first, slide_id: r.last)
      end

      master_groups_users_sql = "SELECT user_id, master_group_id FROM master_groups_users;"
      connection.execute(master_groups_users_sql).each do |r|
        Permission.create(user_id: r.first, master_group_id: r.last)
      end

      presentations_users_sql = "SELECT user_id, presentation_id FROM presentations_users;"
      connection.execute(presentations_users_sql).each do |r|
        Permission.create(user_id: r.first, presentation_id: r.last)
      end

      displays_users_sql = "SELECT user_id, display_id FROM displays_users;"
      connection.execute(displays_users_sql).each do |r|
        Permission.create(user_id: r.first, display_id: r.last)
      end
    end
  end

  def down
    Permission.delete("slide_id IS NOT NULL")
    Permission.delete("master_group_id IS NOT NULL")
    Permission.delete("presentation_id IS NOT NULL")
    Permission.delete("display_id IS NOT NULL")
  end
end
