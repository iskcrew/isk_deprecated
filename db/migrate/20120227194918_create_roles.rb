class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string "role",        :limit => 50,                  :null => false
      t.string "description", :limit => 100, :default => ""
      t.string "controller",  :limit => 50
      t.timestamps
    end
  end
end
