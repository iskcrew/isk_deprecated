class Presentation < ActiveRecord::Base

  has_many :groups, :order => "position ASC", :after_add => :add_group, :before_remove => :remove_group
  belongs_to :effect
  has_many :displays
  
  has_and_belongs_to_many :authorized_users, :class_name => 'User'
    
  
  validate :ensure_effect_exists

  
  attr_accessible :name, :effect_id, :delay
  
  
  AdminRole = 'presentation-admin'
  CreateRole = 'presentation-create'
  
  def can_edit?(user)
    self.authorized_users.include?(user) || user.has_role?('presentation-admin')
  end
  
  
  def total_slides
    self.groups.joins(:master_group => :slides).where(:slides => {:public => true, :deleted => false, :replacement_id => nil}).count
  end
  
  def to_hash
    hash = Hash.new
    hash[:name] = self.name
    hash[:id] = self.id
    hash[:effect] = self.effect_id
    hash[:created_at] = self.created_at.to_i
    hash[:updated_at] = self.updated_at.to_i
    hash[:total_groups] = self.groups.count
    hash[:total_slides] = self.total_slides
    hash[:groups] = Array.new
    self.groups.includes(:master_group => :slides).each do |g|
      hash[:groups]  << g.to_hash
    end
    return hash
  end
  
  
  def duration
    self.total_slides * self.delay
  end
  
  def slide(group, slide)
    g = self.groups.where(:position => group).first!
    return g.master_group.slides.where(:position => slide).first!
  end
  
  def next_slide(group, slide)
    g = self.groups.where(:position => group).first!
    s = g.master_group.slides.where(:position => slide).first!

    if s.last?
      if g.last?
        g = p.groups.first!
      else
        g = g.lower_item
      end
      
      #skip empty groups if needed
      while g.slides.count == 0
        if g.last?
          g = p.groups.first!
        else
          g = g.lower_item
        end
      end
      
      s = g.slides.first!
    else
      s = s.lower_item
    end
    
    return [g.position, s.position]
  end
  
  private
  
  def add_group(group)
    group.move_to_bottom
  end
  
  def remove_group(group)
    group.remove_from_list
  end
  
  def ensure_effect_exists
    errors.add(:effect_id, "^Transition effect is invalid") if self.effect.nil?
  end
  
  
end
