# frozen_string_literal: true
# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class User < ActiveRecord::Base
  require "digest/sha1"

  AdminUsers = ["admin"]

  validates_length_of :username, in: 1..50
  validates_uniqueness_of :username

  has_many :permissions, dependent: :delete_all
  has_many :roles, -> { order "roles.role" },                 through: :permissions, source: :target, source_type: "Role"
  has_many :slides, -> { order "slides.name" },               through: :permissions, source: :target, source_type: "Slide"
  has_many :master_groups, -> { order "master_groups.name" }, through: :permissions, source: :target, source_type: "MasterGroup"
  has_many :presentations, -> { order "presentations.name" }, through: :permissions, source: :target, source_type: "Presentation"
  has_many :displays, -> { order "displays.name" },           through: :permissions, source: :target, source_type: "Display"

  # Cache sweeper
  include CacheSweeper

  def admin?
    User::AdminUsers.include?(self.username)
  end

  def has_role?(request)
    return true if self.admin?
    unless request.is_a? Array
      return self.roles.where(role: request).count > 0
    end
    request.each do |r|
      return true if self.roles.where(role: r).count > 0
    end
    return false
  end

  def roles_text
    text = String.new
    self.roles.each do |r|
      text << r.role << ", "
    end
    return text.chomp(", ")
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
    self[:password] == Digest::SHA1.hexdigest(passwd << self[:salt])
  end

  def self.authenticate(username, passwd)
    user = User.where(username: username).first
    return user if user && user.authenticate(passwd)
    return nil
  end

  def cache_tag
    "user_" + self.id.to_s
  end

private

  def generate_salt
    (0...8).map { 65.+(rand(26)).chr }.join
  end
end
