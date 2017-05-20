# frozen_string_literal: true
class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :name, null: false
      t.integer :status, default: 1, null: false
      t.index :status
      t.index [:event_id, :status]
      t.text :description, null: false
      t.references :event,          index: true
      t.references :about,          index: true, polymorphic: true
      t.timestamps
    end
  end
end
