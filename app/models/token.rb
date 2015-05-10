# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class Token < ActiveRecord::Base
  belongs_to :access, polymorphic: true
  validates :token, :access, presence: true
  validates :token, uniqueness: true
  
  # Authenticate a display per API token
  def self.authenticate_display(token)
    t = Token.where(token: token, access_type: 'Display').first
    if t
      return t.access
    else
      return false
    end    
  end
end
