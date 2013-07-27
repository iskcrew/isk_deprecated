class AddInternalToMasterGroups < ActiveRecord::Migration
  def change
    add_column :master_groups, :internal, :boolean, :default => false
  end
end
