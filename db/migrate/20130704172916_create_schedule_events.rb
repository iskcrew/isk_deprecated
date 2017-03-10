class CreateScheduleEvents < ActiveRecord::Migration
  def change
    create_table :schedule_events do |t|
      t.references :schedule
      t.datetime :at
      t.string :name
      t.string :description
      t.string :location
      t.boolean :major, default: false
      t.timestamps
    end
  end
end
