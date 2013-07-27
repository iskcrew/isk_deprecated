class DropUniqueFromMastergroups < ActiveRecord::Migration
  def change
    remove_index :master_groups, :name
  end
end
