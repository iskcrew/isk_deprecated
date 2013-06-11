class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string 'name', :null => false
      t.boolean 'current', :default => false, :null => false
      t.timestamps
    end
    
    add_index :events, :current
  end
end
