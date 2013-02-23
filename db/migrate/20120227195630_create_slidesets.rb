class CreateSlidesets < ActiveRecord::Migration
  def change
    create_table :slidesets do |t|
      t.integer "slide_id"
      t.integer "presentation_id"
      t.integer "position"

      t.timestamps
    end
  end
end
