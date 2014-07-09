class AddConfigToEvents < ActiveRecord::Migration
  def change
		add_column :events, :config, :text
  end
end
