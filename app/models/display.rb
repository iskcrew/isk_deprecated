class Display < ActiveRecord::Base
  
  
  before_save do
    self.metadata_updated_at = Time.now if self.presentation_id_changed?
  end
  
  before_create do
    self.metadata_updated_at = Time.now
  end
  
  belongs_to :presentation
  belongs_to :current_group, :class_name => "Group"
  belongs_to :current_slide, :class_name => "Slide"
  has_many :override_queues, :order => :position
  
  has_many :display_counts
  
  has_and_belongs_to_many :authorized_users, :class_name => 'User'
  
  
  Timeout = 5 #minutes

  include ModelAuthorization
  
  def websocket_channel
    return "display_" + self.id.to_s
  end
  
  def displays
    return [self]
  end
  
  
  def self.hello(display_name, display_ip, connection_id = nil)
    display = Display.where(:name => display_name).first_or_initialize
    display.ip = ip
    display.websocket_connection_id = connection_id 
    display.last_contact_at = Time.now
    display.last_hello = Time.now
    display.save!
    return display
  end
  
  def override_shown(override)
    self.current_group_id = -1
    oq = self.override_queues.find(override)
    self.current_slide = oq.slide
    self.last_contact_at = Time.now
    oq.destroy
  end
  
  def set_current_slide(group_id, slide_id)
    if group_id != -1
      self.current_group = self.presentation.groups.find(group_id)
    else
      self.current_group_id = -1
    end
    s = Slide.find(slide_id)
    self.current_slide = s
    self.last_contact_at = Time.now
    s.shown_on(self.id)
    
  end

  
  def self.late
    Display.where('monitor = ? AND last_contact_at < ?', true, Timeout.minutes.ago)
  end
  
  def late?
    if self.last_contact_at
      return Time.diff(Time.now, self.last_contact_at,'%m')[:diff].to_i > Timeout
    else
      return false
    end
  end
  
  def uptime
    return nil unless self.last_hello && self.last_contact_at
    
    return Time.diff(self.last_hello, self.last_contact_at, '%h:%m:%s')[:diff]
  end
  
  def to_hash
    h = Hash.new
    h[:metadata_updated_at] = self.metadata_updated_at.to_i
    h[:last_contact_at] = self.last_contact_at.to_i
    h[:updated_at] = self.updated_at.to_i
    h[:created_at] = self.created_at.to_i
    h[:presentation] = self.presentation ? self.presentation.to_hash : Hash.new
    q = Array.new
    self.override_queues.each do |oq|
      q << oq.to_hash
    end
    h[:override_queue] = q
    return h
  end
  

end
