# frozen_string_literal: true
class CreateEffects < ActiveRecord::Migration
  def change
    remove_column :presentations, :effect
    add_column :presentations, :effect_id, :integer, default: 1

    create_table :effects do |t|
      t.string :name, limit: 100
      t.string :description, limit: 200
      t.timestamps
    end
  end
end
