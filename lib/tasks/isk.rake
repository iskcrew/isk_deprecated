namespace :isk do
	desc "Create nginx site configuration file"
	task nginx: :environment do
		template = Rails.root.join('lib', 'nginx.erb')
		isk_public = Rails.root.join('public')
		isk_data = Rails.root.join('data')
		nginx_conf = Rails.root.join('isk_server.conf')
		puts "Writing nginx configuration fragment to isk_server.conf"
		abort "File exists!" if File.exists? nginx_conf
		erb = ERB.new(File.read(template))
		result = erb.result binding
		File.open(nginx_conf, 'w') do |f|
			f << result
		end
		puts "Configuration example created, update your hostname and copy to /etc/nginx/sites-available/ and enable."
	end
	
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
	
	desc "Generate session encryption keys"
	task secrets: :environment do
		file = Rails.root.join('config', 'secrets.yml')
		if File.exists? file
			abort "#{file.to_s} exists, aborting"
		end
		puts "Generating #{file}"
		secrets = {
			'development' => {
				'secret_key_base' => SecureRandom.hex(64)
			},
			'production' => {
				'secret_key_base' => SecureRandom.hex(64)
			},
			'test' => {
				'secret_key_base' => SecureRandom.hex(64)
			}
		}
		File.open(file, 'w') do |f|
			f.puts secrets.to_yaml
		end
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