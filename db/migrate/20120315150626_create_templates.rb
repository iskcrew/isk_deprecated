class CreateTemplates < ActiveRecord::Migration
  def change
    create_table :templates do |t|
      t.string :name, :limit => 100
      t.string :description, :limit => 500
      
      t.timestamps
    end
    
    add_index :templates, :name, :unique => true
  end
end
