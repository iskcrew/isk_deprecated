# frozen_string_literal: true
class AddDurationToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :duration, :integer, default: -1
  end
end
