class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :name, limit: 100

      t.string :filename, limit: 50
      t.timestamps
    end

    add_index :images, :name, unique: true
  end
end
