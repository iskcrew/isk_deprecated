module PresentationsHelper
  def duration_to_text(dur)
    (Time.mktime(0)+dur).strftime("%H:%M:%S")
  end

end
