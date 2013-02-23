class CreateSlides < ActiveRecord::Migration
  def change
    create_table :slides do |t|
      t.string "name", :limit => 100
      t.string "filename", :limit => 50
      t.integer "replacement_id"
      
      t.timestamps
    end
  end
end
