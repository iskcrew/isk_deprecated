# frozen_string_literal: true
class CreatePresentationsUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :presentations_users, id: false do |t|
      t.references :presentation
      t.references :user
    end
  end
end
