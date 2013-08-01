class AddLinecountToScheduleEvents < ActiveRecord::Migration
  def change
		add_column :schedule_events, :linecount, :integer, :default => 1
  end
end
