# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class User < ActiveRecord::Base
  require "digest/sha1"

  AdminUsers = ["admin"].freeze

  validates :username, length: { in: 1..50 }, uniqueness: true

  has_many :permissions, dependent: :delete_all
  has_many :roles, -> { order "roles.role" },                 through: :permissions, source: :target, source_type: "Role"
  has_many :slides, -> { order "slides.name" },               through: :permissions, source: :target, source_type: "Slide"
  has_many :master_groups, -> { order "master_groups.name" }, through: :permissions, source: :target, source_type: "MasterGroup"
  has_many :presentations, -> { order "presentations.name" }, through: :permissions, source: :target, source_type: "Presentation"
  has_many :displays, -> { order "displays.name" },           through: :permissions, source: :target, source_type: "Display"
  has_many :auth_tokens

  def admin?
    User::AdminUsers.include?(username)
  end

  def has_role?(request)
    return true if admin?
    return roles.where(role: request).count.positive? unless request.is_a? Array

    request.each do |r|
      return true if roles.where(role: r).count.positive?
    end
    return false
  end

  def roles_text
    roles.collect(&:role).join(", ")
  end

  def name
    return "#{lastname}, #{firstname}"
  end

  def password=(str)
    self[:salt] = generate_salt unless self[:salt]
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
    user = User.find_by(username: username)
    return user if user && user.authenticate(passwd)
    return nil
  end

  def cache_tag
    "user_" + id.to_s
  end

private

  def generate_salt
    (0...8).map { 65.+(rand(26)).chr }.join
  end
end
