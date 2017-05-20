# frozen_string_literal: true
class AddExternalIdToScheduleEvents < ActiveRecord::Migration
  def change
    add_column :schedule_events, :external_id, :string
  end
end
