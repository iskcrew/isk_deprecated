class MoreTimestampsToDisplays < ActiveRecord::Migration
  def up
    add_column :displays, :last_contact_at, :datetime
    add_column :displays, :metadata_updated_at, :datetime
    Display.update_all(metadata_updated_at: Time.now)
  end

  def down
  end
end
