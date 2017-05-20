# frozen_string_literal: true
class CreateDisplaysUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :displays_users, id: false do |t|
      t.references :display
      t.references :user
    end
  end
end
