# frozen_string_literal: true
class AugmentPermissionsTable < ActiveRecord::Migration
  def up
    add_column :permissions, :id, :primary_key
    change_table :permissions do |t|
      t.timestamps
      t.references :display
      t.references :presentation
      t.references :master_group
      t.references :slide
    end
  end

  def down
    remove_column :permissions, :id
    change_table :permissions do |t|
      t.remove :updated_at
      t.remove :created_at
      t.remove :display_id
      t.remove :presentation_id
      t.remove :master_group_id
      t.remove :slide_id
    end
  end
end
