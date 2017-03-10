class StiToMasterGroups < ActiveRecord::Migration
  def change
    add_column :master_groups, :type, :string
  end
end
