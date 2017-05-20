# frozen_string_literal: true
class AddClockBitToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :show_clock, :boolean, default: true
  end
end
