# frozen_string_literal: true

class FetchJob < ActiveJob::Base
  queue_as :default

  def perform(slide)
    slide.fetch!
  end
end
