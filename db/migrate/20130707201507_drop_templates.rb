# frozen_string_literal: true
class DropTemplates < ActiveRecord::Migration
  def up
    drop_table :slide_templates
  end
end
