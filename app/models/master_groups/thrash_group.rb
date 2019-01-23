# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Group for storing trashed slides in
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class ThrashGroup < MasterGroup
  belongs_to :event
  has_many :slides, -> { order position: :asc }, foreign_key: :master_group_id

  after_initialize do |g|
    g.internal = true
  end

  def name
    "Thrashed slides"
  end
end
