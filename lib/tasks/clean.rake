namespace :clean do
	desc "Clean all old data"
	task all: [:environment, 'clean:deleted_slides', 'clean:images', 'assets:clean'] do
	end
	
	desc "Permanently delete all deleted slides"
	task deleted_slides: :environment do
	end
	
	desc "Delete orphan slide images"
	task images: :environment do
		# Get a array of all slide datafiles
		files = Dir[Slide::FilePath.join('slide_*')].collect {|f| Slide::FilePath.join(f).to_s}
		total = files.size
		puts "#{total} files to consider..."
		
		# Iterate over all slides in db removing files associated to them.
		Slide.all.each do |slide|
			files.delete slide.full_filename.to_s
			files.delete slide.preview_filename.to_s
			files.delete slide.thumb_filename.to_s
			
			if slide.is_a?(ImageSlide) || slide.is_a?(HttpSlide)
				files.delete slide.original_filename.to_s
			end
			
			if slide.respond_to? :data_filename
				files.delete slide.data_filename.to_s
			end
			
			if slide.respond_to? :svg_filename
				files.delete slide.svg_filename.to_s
			end
		end
		
		puts "Keeping: #{total - files.size} files"
		if ENV['delete'].to_i == 1
			puts "Deleting #{files.size} files..."
			files.each do |f|
				File.delete f
			end
		else
			puts "Would delete #{files.size} files:\n #{files.join("\n")}"
			puts "run with delete=1 to really do this."
		end
	end
	
end
