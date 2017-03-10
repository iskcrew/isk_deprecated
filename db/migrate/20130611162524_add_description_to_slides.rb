class AddDescriptionToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :description, :text, default: "", nil: false
  end
end
