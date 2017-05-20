# frozen_string_literal: true
class RenameScheduleGroupIdToSlidegroupIdInSchedules < ActiveRecord::Migration
  def change
    rename_column :schedules, :schedule_group_id, :slidegroup_id
  end
end
