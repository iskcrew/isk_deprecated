# frozen_string_literal: true
class ModifyDeletedColumnOnSlides < ActiveRecord::Migration
  def change
    remove_column :slides, :deleted
    add_column :slides, :deleted, :boolean, default: false
  end
end
