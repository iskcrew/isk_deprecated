class AddDefaultDelayToPresentations < ActiveRecord::Migration
  def change
    remove_column :presentations, :delay
    add_column :presentations, :delay, :integer, default: 30
  end
end
