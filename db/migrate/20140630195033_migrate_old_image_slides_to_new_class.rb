#
#  20140630195033_migrate_old_image_slides_to_new_class.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-30.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# Migrate the old-style image slides into ImageSlide class
# This new class allows the user more options to control the image scaling

class MigrateOldImageSlidesToNewClass < ActiveRecord::Migration
  def up
    sql = "UPDATE slides set type = 'ImageSlide' where type is NULL and is_svg is false;"
    connection = ActiveRecord::Base.connection
    connection.transaction do
      connection.execute(sql)
    end
  end

  def down
    sql = "UPDATE slides set type = NULL, is_svg = false where type = 'ImageSlide';"
    connection = ActiveRecord::Base.connection
    connection.transaction do
      connection.execute(sql)
    end
  end
end
