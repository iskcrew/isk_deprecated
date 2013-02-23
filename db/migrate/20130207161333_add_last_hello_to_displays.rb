class AddLastHelloToDisplays < ActiveRecord::Migration
  def change
    add_column :displays, :last_hello, :datetime
  end
end
