class CreateMastergroups < ActiveRecord::Migration
  def change
    create_table :mastergroups do |t|
      t.string "name", :limit => 100
      t.timestamps
    end
    
    add_column :slides, :mastergroup_id, :integer
    remove_column :slides, :presentation_id
    
  end
end
