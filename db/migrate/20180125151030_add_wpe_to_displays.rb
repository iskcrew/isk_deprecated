class AddWpeToDisplays < ActiveRecord::Migration
  def change
    add_column :displays, :wpe, :boolean
    add_index :displays, :wpe
  end
end
