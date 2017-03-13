class AddDeletedToSlides < ActiveRecord::Migration
  def change
    add_column :slides, :deleted, :boolean
  end
end
