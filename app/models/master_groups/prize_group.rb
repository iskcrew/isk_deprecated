class	PrizeGroup < MasterGroup
  DefaultData = [
  	{:name => '1', :by => '', :pts => ''},
		{:name => '2', :by => '', :pts => ''},
		{:name => '3', :by => '', :pts => ''},
		{:name => '4', :by => '', :pts => ''},
		{:name => '5', :by => '', :pts => ''}
  ]  
	@_data = nil
	
	
	after_save do
		write_data
	end
	
	
  def data
		return @_data if @_data
    if !self.new_record? && File.exists?(data_filename)
      @_data = YAML.load(File.read(data_filename))
		end
		return @_data.blank? ? self.class::DefaulData : @_data
  end
  
  def data=(d)
    if d.nil?
			d = self.class::DefaulData
		end
	
	  @_data=d
  end
	
	def generate_slides
		@header = self.name
		@data = Array.new
		
		index = 1
		data.each do |d|
			if d[:name]
				@data << {:place => index.ordinalize, :name => d[:name]}
				@data << {:pts => d[:pts], :name => d[:by]}
				index += 1
			end
		end
		
		(index - self.slides.where(:type => InkscapeSlide.sti_name).count).times do
			slide = InkscapeSlide.new
			slide.name = self.name
			self.slides << slide
			slide.save!
		end
		
		self.hide_slides
		
		result_slides = self.slides.where(:type => InkscapeSlide.sti_name)
		
		@data.reverse!
		
		index.times do
			slide = result_slides.last
			slide.name = @header
			self.slides << slide
			slide.svg_data = template.result(binding)
			slide.save!
			slide.delay.generate_images
			@data.pop
			@data.pop
			result_slides.pop
		end	
		
	end
	
	
	
	private
	
	def template
		template = ERB.new(File.read(Rails.root.join('data', 'templates', 'prize.svg.erb')))
	end
	
	def data_filename
		if self.id
			return Rails.root.join('data', 'prizes', 'prize_group_' + self.id.to_s)
		else
			return nil
		end
	end
  
	def write_data
    unless self.new_record?
      File.open(data_filename,  'w') do |f|
        f.write self.data.to_yaml
      end
    end
  end
	
end