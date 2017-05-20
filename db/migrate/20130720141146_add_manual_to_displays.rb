# frozen_string_literal: true
class AddManualToDisplays < ActiveRecord::Migration
  def change
    add_column :displays, :manual, :boolean, default: false
  end
end
