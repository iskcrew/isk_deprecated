# frozen_string_literal: true
class AddIsSvgToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :is_svg, :boolean, default: false
  end
end
