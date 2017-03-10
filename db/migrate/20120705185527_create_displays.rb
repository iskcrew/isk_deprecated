class CreateDisplays < ActiveRecord::Migration
  def change
    create_table :displays do |t|
      t.string :name, limit: 50
      t.string :ip, limit: 12
      t.integer :presentation_id
      t.timestamps
    end
    add_index :displays, :name, unique: true
  end
end
