# frozen_string_literal: true
class AddSlideSti < ActiveRecord::Migration
  def up
    add_column :slides, :type, :string
  end

  def down
  end
end
