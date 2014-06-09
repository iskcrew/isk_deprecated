class AddObjectIdToSlides < ActiveRecord::Migration
  def change
		add_column :slides, :object_id, :integer, index: true
  end
end
