# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class Permission < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :user, touch: true

  def cache_tag
    "permission_#{id}"
  end
end
