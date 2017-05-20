# frozen_string_literal: true
class AddObjectIdToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :foreign_object_id, :integer, index: true
  end
end
