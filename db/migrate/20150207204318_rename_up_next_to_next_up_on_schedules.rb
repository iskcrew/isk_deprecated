class RenameUpNextToNextUpOnSchedules < ActiveRecord::Migration
  def change
    rename_column :schedules, :up_next, :next_up
    rename_column :schedules, :up_next_group_id, :next_up_group_id
  end
end
