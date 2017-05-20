# frozen_string_literal: true
class AssignSchedulesToEvents < ActiveRecord::Migration
  def up
    sql = "UPDATE schedules JOIN master_groups ON"\
          " schedules.slidegroup_id = master_groups.id SET"\
          " schedules.event_id = master_groups.event_id;"
    connection = ActiveRecord::Base.connection
    connection.transaction do
      connection.execute(sql)
    end
  end

  def down
  end
end
