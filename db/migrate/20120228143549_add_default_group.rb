# frozen_string_literal: true
class AddDefaultGroup < ActiveRecord::Migration
  def change
    remove_column :slides, :master_group_id
    add_column :slides, :master_group_id, :integer, default: 1
  end
end
