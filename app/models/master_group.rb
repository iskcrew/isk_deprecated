class MasterGroup < ActiveRecord::Base
  
  Ungrouped_id = 1 # Group for ungroupped slides


  has_many :slides, :order => 'position ASC', :after_add => :add_slide, :before_remove => :remove_slide
  has_many :groups
  has_and_belongs_to_many :authorized_users, :class_name => 'User'
  belongs_to :event

  validates :name, :uniqueness => true, :presence => true, :length => { :maximum => 100 }
  validates :internal, :inclusion => { :in => [true, false] }

  include ModelAuthorization
  
  scope :orphan, joins('LEFT OUTER JOIN groups on master_groups.id = groups.master_group_id').where('groups.id IS NULL and master_groups.id <> ?', MasterGroup::Ungrouped_id)
  scope :defined_groups, where(:internal => false).order('name')
  
  before_create do |g|
    g.event = Event.current unless g.event
  end
  
  def self.ungrouped
    Event.current.ungrouped
  end
  
  def self.thrashed
    Event.current.thrashed
  end
  
  def self.current
    self.where(:event_id => Event.current.id).where(:internal => false)
  end
  
  def presentations
    Presentation.joins(:groups => :master_group).where('master_groups.id = ?', self.id).uniq.all
  end
  
  def displays
    Display.joins(:presentation => {:groups => :master_group}).where(:master_groups => {:id => self.id}).uniq
  end
  
  def hide_slides
    self.slides.each do |s|
      s.public = false
      s.save!
    end
  end
  
  def publish_slides
    self.slides.each do |s|
      s.public = true
      s.save!
    end
  end
  
  def public_slides
    
  end

  def destroy
    MasterGroup.transaction do
      self.slides.each do |s|
        s.master_group_id = MasterGroup::Ungrouped_id
        s.save!
      end

      super
    end
  end

  private
  
  def add_slide(slide)
    slide.move_to_bottom
  end
  
  def remove_slide(slide)
    slide.remove_from_list
  end


end
