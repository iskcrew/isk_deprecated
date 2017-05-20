# frozen_string_literal: true
class AddEventIdToMasterGroups < ActiveRecord::Migration
  def change
    add_column :master_groups, :event_id, :integer
    add_index :master_groups, :event_id
  end
end
