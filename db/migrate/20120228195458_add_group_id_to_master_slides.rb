# frozen_string_literal: true
class AddGroupIdToMasterSlides < ActiveRecord::Migration
  def change
    add_column :master_slides, :master_group_id, :integer, default: 1
  end
end
