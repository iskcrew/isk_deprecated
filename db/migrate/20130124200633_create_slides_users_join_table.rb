class CreateSlidesUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :slides_users, :id => false do |t|
      t.references :slide
      t.references :user
    end
  end

end
