class AddIsSvgToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :is_svg, :boolean, default: false
  end
end
