# frozen_string_literal: true
class RenameTemplatesToSlideTemplates < ActiveRecord::Migration
  def change
    rename_table :templates, :slide_templates
  end
end
