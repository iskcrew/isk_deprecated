class Effect < ActiveRecord::Base
  has_many :presentations
  
  validates :name, :uniqueness => true, :presence => true, :length => { :maximum => 100 }
  validates :description, :length => { :maximum => 200 }, :allow_nil => true
  
end
