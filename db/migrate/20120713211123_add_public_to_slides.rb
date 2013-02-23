class AddPublicToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :public, :boolean, :default => false
  end
end
