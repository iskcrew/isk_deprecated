class AddKindToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :kind, :string, default: "request", null: false
  end
end
