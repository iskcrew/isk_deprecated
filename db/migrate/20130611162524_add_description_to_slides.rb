# frozen_string_literal: true
class AddDescriptionToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :description, :text, default: "", nil: false
  end
end
