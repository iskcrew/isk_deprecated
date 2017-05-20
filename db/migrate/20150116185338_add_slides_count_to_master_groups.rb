# frozen_string_literal: true
class AddSlidesCountToMasterGroups < ActiveRecord::Migration
  def up
    add_column :master_groups, :slides_count, :integer
    MasterGroup.all.each do |mg|
      MasterGroup.reset_counters(mg.id, :slides)
    end
  end

  def down
    remove_column :master_groups, :slides_count, :integer
  end
end
