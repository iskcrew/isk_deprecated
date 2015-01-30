namespace :isk do
	desc "Backup the database"
	task sql_backup: :environment do
		backup_file = Tempfile.new 'isk-database-backup'
		sql_backup(sql_backup_location)
		puts "SQL backup created: #{sql_backup_location.to_s}"
	end

	desc "Create zip with all slide data and the database dump"
	task full_backup: :sql_backup do
		tmp_file = Tempfile.new 'isk-full-backup'
		backup_file = Rails.root.join("isk_backup-#{Time.now.strftime("%F-%H%M")}.tar.gz").to_s
		# We need relative location for the sql file
		sql_file = sql_backup_location.to_s.partition(Rails.root.to_s).last[1..-1]
		cmd = "tar -czf #{tmp_file.path} -C #{Rails.root.to_s} data #{sql_file}"
		puts "Creating the archive..."
		system cmd
		FileUtils.mv tmp_file.path, backup_file
		puts "Created full backup: #{backup_file}"
		tmp_file.unlink
	end
	
	private
	
	def sql_backup(backup_file)
		cmd = nil
		with_config do |app, host, db, user|
			cmd = "pg_dump "
			cmd << "--host #{host} " if host.present?
			cmd << "--username #{user} " if user.present?
			cmd << "--clean --no-owner #{db} > #{backup_file}"
		end
		puts "Creating database dump..."
		system cmd
	end
	
	def sql_backup_location
		@location ||= Rails.root.join('db', "isk_database_backup-#{Time.now.strftime("%F-%H%M")}.sql")
	end

	def with_config
		yield Rails.application.class.parent_name.underscore,
		ActiveRecord::Base.connection_config[:host],
		ActiveRecord::Base.connection_config[:database],
		ActiveRecord::Base.connection_config[:username]
	end
end