class AddDeletedToTemplates < ActiveRecord::Migration
  def change
		add_column :slide_templates, :deleted, :boolean, default: false, nil: false
		add_index :slide_templates, :deleted
  end
end
