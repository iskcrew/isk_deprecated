# ISK - A web controllable slideshow system
#
# model_authorization.rb - Generic support for per - object
# ACL's
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module ModelAuthorization
  # Module for dealing with user roles and permissions
  # Expects the base model to have authorized_users relation to user model

  extend ActiveSupport::Concern

  included do
    has_many :permissions, as: :target
    has_many :authorized_users, through: :permissions, source: :user, class_name: "User"
  end

  # Can a given user edit this instance of a model?
  def can_edit?(user)
    user.has_role?(self.class.auth_roles[:admin]) || authorized_users.include?(user)
  end

  # Can a user hide this instance? (Only appropriate for slides currently)
  # FIXME: Should bind only to slides
  def can_hide?(user)
    user.has_role?(self.class.auth_roles[:hide]) || can_edit?(user)
  end

  # Can a user add slides to override queue on this display? (only for displays currently)
  # FIXME: Should bind only to displays
  def can_override?(user)
    user.has_role?([self.class.auth_roles[:admin], self.class.auth_roles[:override]]) || authorized_users.include?(user)
  end

  # Does the user have full admin priviledges on this instance?
  def admin?(user)
    user.has_role?(self.class.auth_roles[:admin])
  end

  module ClassMethods
    # Class methods to be defined on our base class

    # List of all role-strings on this model
    def auth_roles
      base_name = base_class.name.downcase
      @roles ||= {
        admin:    "#{base_name}-admin",
        hide:     "#{base_name}-hide",
        create:   "#{base_name}-create",
        override: "#{base_name}-override"
      }
    end

    # Can user create a new instance of this model?
    def can_create?(user)
      user.has_role?([auth_roles[:admin], auth_roles[:create]])
    end

    # List of all displays a user can add overrides on
    def can_override(user)
      return relation if user.has_role?([auth_roles[:admin], auth_roles[:override]])
      return joins(:authorized_users).where(users: { id: user.id })
    end

    # List of all objects user can edit
    def can_edit(user)
      return relation if user.has_role?(auth_roles[:admin])
      joins(:authorized_users).where("users.id = ?", user.id)
    end

    # Does user have admin priviledges on all objects of this type?
    def admin?(user)
      user.has_role?(auth_roles[:admin])
    end
  end

private
end
