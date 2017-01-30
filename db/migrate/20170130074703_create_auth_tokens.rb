class CreateAuthTokens < ActiveRecord::Migration
  def change
    create_table :auth_tokens do |t|
			t.references :user, index: true, null: false
			t.string :token, null: false
			t.index :token
      t.timestamps null: false
    end
  end
end
