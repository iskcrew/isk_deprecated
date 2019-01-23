class AddWpeToDisplays < ActiveRecord::Migration
  def change
    add_column :displays, :wpe, :boolean, default: false, nil: false
    add_index :displays, :wpe
  end
end
