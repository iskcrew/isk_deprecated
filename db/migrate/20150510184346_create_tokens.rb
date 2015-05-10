class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.string :token, nil: false
      t.references :access, polymorphic: true, index: true
      t.timestamps null: false
    end
  
    add_index :tokens, :token, unique: true
  end
end
