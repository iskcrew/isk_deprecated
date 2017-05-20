# frozen_string_literal: true
class DropSlidesTable < ActiveRecord::Migration
  def up
    drop_table :slides
  end

  def down
  end
end
