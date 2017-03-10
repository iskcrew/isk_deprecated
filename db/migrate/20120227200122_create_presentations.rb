class CreatePresentations < ActiveRecord::Migration
  def change
    create_table :presentations do |t|
      t.string "name", limit: 100
      t.integer "effect"
      t.integer "delay"
      t.timestamps
    end
  end
end
