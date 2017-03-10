class MakePermissionsHavePolymorphicTarget < ActiveRecord::Migration
  def change
    add_reference :permissions, :target, polymorphic: true, index: true

    {
      role_id: "Role",
      master_group_id: "MasterGroup",
      display_id: "Display",
      presentation_id: "Presentation",
      slide_id: "Slide"
    }.each_pair do |column, type|
      sql = "UPDATE permissions SET target_id = #{column}, target_type = '#{type}' WHERE #{column} is not NULL;"
      connection = ActiveRecord::Base.connection
      connection.transaction do
        connection.execute(sql)
      end
    end
  end
end
