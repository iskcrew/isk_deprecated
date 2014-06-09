class CreateTemplateFields < ActiveRecord::Migration
  def change
    create_table :template_fields do |t|
			t.references :template, index: true
			t.boolean :editable, default: false
			t.boolean :multiline, default: false
			t.string :color, default: '#00ff00'
			t.text	:default_value
			t.string :element_id
			t.integer :field_order

      t.timestamps
    end
  end
end
