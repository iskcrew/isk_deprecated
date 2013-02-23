class Image < ActiveRecord::Base
  attr_accessible :name

  PreviewSize = 400
  FilePath = Rails.root.join('data', 'images')


  def destroy
    if File.exists?(self.original_filename)
      File.delete(self.original_filename)
    end

    if File.exists?(self.full_filename)
      File.delete(self.full_filename)
    end

    if File.exists?(self.preview_filename)
      File.delete(self.preview_filename)
    end
    
    super
    
  end


  def generate_images
    picture = Magick::ImageList.new(self.original_filename)
    picture = picture[0]
  
    picture.write(self.full_filename)
  
    picture.resize_to_fit!(Image::PreviewSize,Image::PreviewSize)
    picture.write(self.preview_filename)
  
    self.save!
    
  end
  
  def preview_filename
    FilePath.join(self.filename + '_preview.png')
  end
  
  def full_filename
    FilePath.join(self.filename + '_full.png')
  end
  
  def original_filename
    FilePath.join(self.filename + '_original')
  end
  
  private
  

end
