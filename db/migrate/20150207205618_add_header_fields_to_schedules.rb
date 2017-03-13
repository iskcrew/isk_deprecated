class AddHeaderFieldsToSchedules < ActiveRecord::Migration
  def change
    add_column :schedules, :next_up_header, :string
    add_column :schedules, :slide_header, :string
  end
end
