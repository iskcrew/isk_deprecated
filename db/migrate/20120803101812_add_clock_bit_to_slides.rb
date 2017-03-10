class AddClockBitToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :show_clock, :boolean, default: true
  end
end
