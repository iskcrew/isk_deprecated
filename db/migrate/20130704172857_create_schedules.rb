class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.references :event
      t.string :name
      t.integer :schedule_group_id
      t.integer :up_next_group_id    
      t.boolean :up_next, :default => true
      t.integer :max_slides, :default => -1
      t.integer :min_events_on_next_day, :default => 3
      t.timestamps
    end
  end
end
