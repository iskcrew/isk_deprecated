class AddFilenameBackToImages < ActiveRecord::Migration
  def change
    add_column :images, :filename, :string, :limit => 50
  end
end
