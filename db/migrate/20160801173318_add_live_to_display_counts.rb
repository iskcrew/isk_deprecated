class AddLiveToDisplayCounts < ActiveRecord::Migration
  def change
		add_column :display_counts, :live, :boolean, default: false, nil: false
		add_index :display_counts, :live
  end
end
