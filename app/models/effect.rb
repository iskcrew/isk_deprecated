# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class Effect < ActiveRecord::Base
  has_many :presentations
  
  validates :name, :uniqueness => true, :presence => true, :length => { :maximum => 100 }
  validates :description, :length => { :maximum => 200 }, :allow_nil => true
  
end
