# frozen_string_literal: true
class DropImagesModel < ActiveRecord::Migration
  def up
    drop_table :images
  end
end
