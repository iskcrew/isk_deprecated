class Event < ActiveRecord::Base
  attr_accessible :name, :current
  
  before_save :set_current_event
  
  has_many :master_groups
  
  
  belongs_to :thrashed, :class_name => 'MasterGroup', :foreign_key => 'thrashed_id'
  belongs_to :ungrouped, :class_name => 'MasterGroup', :foreign_key => 'ungrouped_id'
  
  validates :name, :uniqueness => true, :presence => true
  validates :current, :inclusion => { :in => [true, false] }  
  
  after_create do |e|
    e.ungrouped = MasterGroup.where(:name => ('Ungrouped slides for ' + e.name)).first_or_create
    e.ungrouped.internal = true
    e.ungrouped.save!
    
    e.thrashed = MasterGroup.where(:name => ('Thrashed slides for ' + e.name)).first_or_create
    e.thrashed.internal = true
    e.thrashed.save!
    
    e.master_groups << e.ungrouped
    e.master_groups << e.thrashed
    
    e.save!
  end
  
  
  #TODO: tietokannan päähän triggeri joka varmistaa että ainankin yksi tapahtuma on aktiivinen?
  def self.current
    self.where(:current => true).first!
  end
  
  private
  
  #Varmistetaan että vain yhdella tapahtumalla on current -bitti päällä
  def set_current_event
    if self.current
      Event.update_all :current => false
    end
  end
  
end
