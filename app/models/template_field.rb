# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class TemplateField < ActiveRecord::Base
  belongs_to :template

  include RankedModel
  ranks :field_order, with_same: :slide_template_id

  scope :editable, -> { where editable: true }
end
