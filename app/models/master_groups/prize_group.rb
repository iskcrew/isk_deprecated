# ISK - A web controllable slideshow system
#
# master_group.rb STI inherited group with a generator
# for making price ceremony slidesets
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class PrizeGroup < MasterGroup
  DefaultData = HashWithIndifferentAccess.new(
    title: "Competiton Compo",
    template_id: nil,
    awards: [
      { name: "", by: "", pts: "" },
      { name: "", by: "", pts: "" },
      { name: "", by: "", pts: "" },
      { name: "", by: "", pts: "" },
      { name: "", by: "", pts: "" }
    ]
  )
  @_data = nil

  after_save do
    write_data
    generate_slides
  end

  def data
    return @_data if (@_data.present? && @_data.is_a?(Hash))
    if !self.new_record? && File.exists?(data_filename)
      @_data = YAML.load(File.read(data_filename))
    end

    # Deal with legacy data
    if @_data.is_a? Array
      d = DefaultData
      d[:awards] = @_data
      @_data = d
    end

    return @_data.blank? ? self.class::DefaultData : @_data
  end

  def data=(d)
    if d.nil?
      d = DefaultData
    end

    Rails.logger.debug d.class
    Rails.logger.debug d

    d[:title] = DefaultData[:title] unless d.key?(:title)
    d[:awards] = DefaultData[:awards] unless d.key?(:awards)

    d.keep_if do |k, v|
      DefaultData.key? k
    end

    @_data = d
    write_data
  end

  def generate_slides
    # Determinate how many places were awarded
    awards = []
    data[:awards].each do |a|
      if a[:name].present?
        awards << a
      end
    end
    template = SlideTemplate.find(data[:template_id])
    # Find the PrizeSlides for this group
    slides = self.slides.where(type: PrizeSlide.sti_name).to_a
    # Destroy excess slides, we need awards + 1 slides because first slide
    # is only for the competition name.
    while (slides.size > (awards.size + 1)) do
      s = slides.pop
      s.destroy
    end
    # Create more slides if needed
    # We need awards.size +1 slides, because first slide doesn't show any awards
    ((awards.size + 1) - slides.size).times do
      s = PrizeSlide.new(name: "Prizes for: #{data[:title]}")
      s.template = template
      s.master_group = self
      s.save!
      slides << s
    end

    self.slides.where(type: PrizeSlide.sti_name).each do |s|
      s.template = template
      s.save!
    end

    self.reload
    slides = self.slides.where(type: PrizeSlide.sti_name).to_a

    s = slides.shift
    s.slidedata = empty_template_data
    s.save!
    s.generate_images_later

    # Create the slides revealing the awards in ascending order
    total_awards = awards.size

    total_awards.times do
      d = empty_template_data

      # get the last ungenerated slide
      s = slides.pop

      awards.reverse.each_with_index do |a, i|
        field = total_awards - i
        d["place_#{field}_number".to_sym] = "#{field}#{field.ordinal}"
        d["place_#{field}_pts".to_sym] = a[:pts]
        d["place_#{field}_entry".to_sym] = a[:name]
        d["place_#{field}_by".to_sym] = a[:by]
      end
      s.slidedata = d
      s.save!
      s.generate_images_later

      # remove the highest award place remaining
      awards.shift
    end

    # Mark slides as public and hide the clock
    self.slides.where(type: PrizeSlide.sti_name).each do |s|
      s.public = true
      s.show_clock = false
      s.save!
    end
  end

private

  def empty_template_data
    d = {
      header: "Results",
      subheader: data[:title],
    }

    (1..5).each do |i|
      d["place_#{i}_number".to_sym] = ""
      d["place_#{i}_pts".to_sym] = ""
      d["place_#{i}_entry".to_sym] = ""
      d["place_#{i}_by".to_sym] = ""
    end

    return d
  end

  def data_filename
    if self.id
      return Rails.root.join("data", "prizes", "prize_group_#{id}")
    else
      return nil
    end
  end

  def write_data
    unless self.new_record?
      File.open(data_filename,  "w") do |f|
        f.write self.data.to_yaml
      end
    end
  end
end
