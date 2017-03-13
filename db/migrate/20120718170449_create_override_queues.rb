class CreateOverrideQueues < ActiveRecord::Migration
  def change
    create_table :override_queues do |t|
      t.integer :display_id
      t.integer :position
      t.integer :duration
      t.integer :slide_id
      t.timestamps
    end
  end
end
