class CreateDisplayCounts < ActiveRecord::Migration
  def change
    create_table :display_counts do |t|
      t.integer :count, :default => 0, :nil => false
      t.references :slide
      t.references :display
      t.timestamps
    end
  end
end
