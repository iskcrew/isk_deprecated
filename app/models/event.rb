class Event < ActiveRecord::Base
  attr_accessible :name
  
  before_save :set_current_event
  
  has_many :master_groups
  
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
