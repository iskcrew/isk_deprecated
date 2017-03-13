# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# Cashier gem allows us to expire cache fragments by tags
# The tags in use:
# slide_<id>::            Expires on any changes to this slide
# master_group_<id>::     Expires on any changes to this master_group
# presentation_<id>::     Expires on any changes to this presentation
# groups::                Expires on any change to any group
# slides::                Expires on any change to any slide

module CacheSweeper
  extend ActiveSupport::Concern

  # Run code in the context of model including this module
  included do
    # Expire the caches after commit
    after_commit :expire_cache
  end

  # Define class methods for the model including this
  module ClassMethods; end

private

  def expire_cache
    if self.is_a? Slide
      Cashier.expire "slides"

      # Expire presentation fragments
      self.presentations.each do |p|
        Cashier.expire p.cache_tag
      end

      Cashier.expire self.master_group.cache_tag
      if self.changed.include? "master_group_id"
        # We want to expire also the old group
        if g = MasterGroup.where(id: self.master_group_id_was).first
          Cashier.expire g.cache_tag
        end
      end
    elsif self.is_a? MasterGroup
      Cashier.expire "groups"
      self.presentations.each do |p|
        Cashier.expire p.cache_tag
      end
    elsif self.is_a? Presentation

    elsif self.is_a? User

    elsif self.is_a? Group
      Cashier.expire self.presentation.cache_tag
    elsif self.is_a? Permission
      Cashier.expire self.user.cache_tag
    else
      raise ArgumentError, "Unexpected object class: " + self.class.name
    end

    Cashier.expire self.cache_tag
  end
end
