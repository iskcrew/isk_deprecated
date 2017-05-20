# frozen_string_literal: true
class RenameMasterSlidesToSlides < ActiveRecord::Migration
  def change
    rename_table :master_slides, :slides
  end
end
