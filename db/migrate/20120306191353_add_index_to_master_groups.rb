class AddIndexToMasterGroups < ActiveRecord::Migration
  def change
    add_index :master_groups, :name, :unique => true
  end
end
