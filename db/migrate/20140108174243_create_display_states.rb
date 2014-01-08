class CreateDisplayStates < ActiveRecord::Migration
  def change
    create_table :display_states do |t|

      t.timestamps
    end
  end
end
