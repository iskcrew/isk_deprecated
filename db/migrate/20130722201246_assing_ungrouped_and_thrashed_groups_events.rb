class AssingUngroupedAndThrashedGroupsEvents < ActiveRecord::Migration
  def up
    Event.where(ungrouped_id: nil).each do |e|
      e.ungrouped = MasterGroup.where(name: "Ungrouped slides for #{e.name}")
                               .first_or_create
      e.ungrouped.internal = true
      e.save!
      e.master_groups << e.ungrouped
    end

    Event.where(thrashed_id: nil).each do |e|
      e.thrashed = MasterGroup.where(name: "Thrashed slides for #{e.name}")
                              .first_or_create
      e.thrashed.internal = true
      e.save!
      e.master_groups << e.thrashed
    end
  end
end
