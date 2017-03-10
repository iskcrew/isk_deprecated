class AddConfigColumnsToEvents < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.integer :resolution,                default: 1,   null: false

      t.integer :schedules_per_slide,       default: 9,   null: false
      t.integer :schedules_line_length,     default: 30,  null: false
      t.integer :schedules_tolerance,       default: 15,  null: false
      t.string  :schedules_subheader_fill,  default: "#e2e534", null: false
      t.integer :schedules_time_indent,     default: 60,  null: false
      t.integer :schedules_event_indent,    default: 290, null: false
      t.integer :schedules_font_size,       default: 72,  null: false
      t.integer :schedules_line_spacing,    default: 100, null: false

      t.integer :simple_heading_font_size,  default: 120, null: false
      t.integer :simple_heading_x,          default: 60,  null: false
      t.integer :simple_heading_y,          default: 130, null: false
      t.integer :simple_body_margin_left,   default: 60,  null: false
      t.integer :simple_body_margin_right,  default: 1920 - 60, null: false
      t.integer :simple_body_y,             default: 280, null: false
    end
  end
end
