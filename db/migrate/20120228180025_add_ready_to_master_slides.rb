# frozen_string_literal: true
class AddReadyToMasterSlides < ActiveRecord::Migration
  def change
    add_column :master_slides, :ready, :boolean, default: false
  end
end
