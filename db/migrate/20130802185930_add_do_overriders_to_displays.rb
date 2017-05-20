# frozen_string_literal: true
class AddDoOverridersToDisplays < ActiveRecord::Migration
  def change
    add_column :displays, :do_overrides, :boolean, default: true
  end
end
