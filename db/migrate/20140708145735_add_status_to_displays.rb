class AddStatusToDisplays < ActiveRecord::Migration
  def change
		add_column :displays, :status, :string, default: 'disconnected'
  end
end
