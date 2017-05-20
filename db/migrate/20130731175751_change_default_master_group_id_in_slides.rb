# frozen_string_literal: true
class ChangeDefaultMasterGroupIdInSlides < ActiveRecord::Migration
  def up
    change_column_default :slides, :master_group_id, nil
    MasterGroup.find(1).slides.each do |slide|
      slide.update_column(:master_group_id, Event.current.ungrouped.id)
    end
  end

  def down
    change_column_default :slides, :master_group_id, 1
  end
end
