class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.integer "position"
      t.integer "master_group_id"
      t.integer "presentation_id"
      t.timestamps
    end
  end
end
