# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class User < ActiveRecord::Base
  require 'digest/sha1'
  
  AdminUsers = ['admin']
    
  validates_length_of :username, :in=>1..50
  validates_uniqueness_of :username
  
	has_many :permissions
	
  has_many :roles, 						through: :permissions, order: 'roles.role'
  has_many :slides, 					through: :permissions
  has_many :master_groups, 		through: :permissions
  has_many :presentations, 		through: :permissions
  has_many :displays, 				through: :permissions
  
  attr_protected :password
  attr_protected :salt
  attr_protected :username

  include ModelAuthorization

  def admin?
    User::AdminUsers.include?(self.username)
  end

  def has_role?(request)
    return true if self.admin?
    if request.is_a? Array
      request.each do |r|
        return true if self.roles.where(:role => r).count > 0
      end
      return false
    else
      return self.roles.where(:role => request).count > 0
    end
  end
  
  def roles_text
    text = ""
    self.roles.each do |r|
      text << r.role << ", "
    end
    return text.chomp(', ')
  end
  
  def name
    return self[:lastname] << ", " << self[:firstname]
  end
    
  def password=(str) 
    unless self[:salt]
      self[:salt] = generate_salt
    end
    self[:password] = Digest::SHA1.hexdigest(str << self[:salt])
    return true
  end 

  def password 
    ""  
  end 

  def authenticate(passwd)
    if self[:password] == Digest::SHA1.hexdigest(passwd << self[:salt])
      return true
    else
      return false
    end
  end

  def self.authenticate(username, passwd) 
    user = User.where(:username => username).first
    if user && user.authenticate(passwd)
      return user
    else
      return nil
    end
  end
	
	def cache_tag
		"user_" + self.id.to_s
	end

  private
  
  def generate_salt
    (0...8).map{65.+(rand(26)).chr}.join
  end


end
