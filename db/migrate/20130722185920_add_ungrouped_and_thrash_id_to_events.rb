class AddUngroupedAndThrashIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :ungrouped_id, :integer
    add_column :events, :thrashed_id, :integer
  end
end
