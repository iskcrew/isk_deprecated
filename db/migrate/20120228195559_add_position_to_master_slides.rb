class AddPositionToMasterSlides < ActiveRecord::Migration
  def change
    add_column :master_slides, :position, :integer
  end
end
