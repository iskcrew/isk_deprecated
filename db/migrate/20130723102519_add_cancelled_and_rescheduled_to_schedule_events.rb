class AddCancelledAndRescheduledToScheduleEvents < ActiveRecord::Migration
  def change
    add_column :schedule_events, :cancelled, :boolean, :default => false
    add_column :schedule_events, :rescheduled, :boolean, :default => false
  end
end
