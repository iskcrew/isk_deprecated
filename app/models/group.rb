class Group < ActiveRecord::Base
  belongs_to :master_group
  belongs_to :presentation, :touch => true
  acts_as_list :scope => :presentation
  
  def to_hash
    hash = Hash.new
    hash[:name] = self.name
    hash[:id] = self.id
    hash[:master_id] = self.master_group.id
    hash[:position] = self.position
    hash[:total_slides] = self.master_group.slides.public.count
    hash[:created_at] = self.master_group.created_at.to_i
    hash[:updated_at] = self.master_group.updated_at.to_i
    hash[:slides] = Array.new
    self.public_slides.each do |s|
      hash[:slides] << s.to_hash(self.presentation.delay)
    end
    return hash
      
  end
  
  def slides
    self.master_group.slides
  end
  
  def public_slides
    self.master_group.slides.where(:public => true)
  end
  
  def name
    self.master_group.name
  end
  
  def presentation_id=(presentation_id)
    if presentation_id != @presentation_id
      self.transaction do
        remove_from_list if in_list?
        super
        assume_bottom_position unless new_record?
      end
    end
  end

  def presentation=(presentation)
    self.presentation_id = presentation.id
  end
    
end
