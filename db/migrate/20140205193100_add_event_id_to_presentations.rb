# frozen_string_literal: true
class AddEventIdToPresentations < ActiveRecord::Migration
  def change
    add_column :presentations, :event_id, :integer
  end
end
