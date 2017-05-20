# frozen_string_literal: true
class AddDefaultsToOverridequeues < ActiveRecord::Migration
  def up
    change_column :override_queues, :duration, :integer, default: 60
  end

  def down
    change_column :override_queues, :duration, :integer, default: nil
  end
end
