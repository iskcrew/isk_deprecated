# frozen_string_literal: true
class RenameTablesAgain < ActiveRecord::Migration
  def change
    rename_table :masterslides, :master_slides
    rename_table :mastergroups, :master_groups
    rename_column :slides, :slide_id, :master_slide_id
    rename_column :slides, :mastergroup_id, :master_group_id
  end
end
