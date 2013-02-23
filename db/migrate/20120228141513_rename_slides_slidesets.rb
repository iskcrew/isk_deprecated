class RenameSlidesSlidesets < ActiveRecord::Migration
  def change
    rename_table :slides, :masterslides
    rename_table :slidesets, :slides
  end
end
