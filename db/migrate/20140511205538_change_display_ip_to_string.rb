class ChangeDisplayIpToString < ActiveRecord::Migration
  def up
		change_column :display_states, :ip, :string
  end

  def down
  end
end
