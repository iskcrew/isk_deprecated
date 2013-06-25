class AddImagesModifiedAtToSlides < ActiveRecord::Migration
  def up
    add_column :slides, :images_updated_at, :datetime
    
    Slide.all.each do |s|
      if File.exists?(s.full_filename)
        s.images_updated_at = File.mtime(s.full_filename)
        s.save!
      end
    end 
  end
  
  def down
    remove_column :slides, :images_updated_at
    
  end
end
