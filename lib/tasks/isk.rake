namespace :isk do
  desc "Runs all installation tasks; sets up the database, secrets and creates nginx config file"
  task setup: ["db:setup", "isk:secrets", "isk:nginx", "assets:precompile"] do
  end

  desc "Create nginx site configuration file"
  task nginx: :environment do
    template = Rails.root.join("lib", "nginx.erb")
    isk_public = Rails.root.join("public")
    isk_data = Rails.root.join("data")
    nginx_conf = Rails.root.join("isk_server.conf")
    puts "Writing nginx configuration fragment to isk_server.conf"
    abort "File exists!" if File.exist? nginx_conf
    erb = ERB.new(File.read(template))
    result = erb.result binding
    File.open(nginx_conf, "w") do |f|
      f << result
    end
    puts "Configuration example created, update your hostname and copy to /etc/nginx/sites-available/ and enable."
  end

  desc "Backup the database"
  task sql_backup: :environment do
    sql_backup(sql_backup_location)
    puts "SQL backup created: #{sql_backup_location}"
  end

  desc "Create zip with all slide data and the database dump"
  task full_backup: :sql_backup do
    backup_file = Rails.root.join("isk_backup-#{Time.now.strftime("%F-%H%M")}.tar.gz").to_s
    # We need relative location for the sql file
    sql_file = sql_backup_location.to_s.partition(Rails.root.to_s).last[1..-1]
    cmd = "tar -czf #{backup_file} -C #{Rails.root} data #{sql_file}"
    puts "Creating the archive..."
    system cmd
    puts "Created full backup: #{backup_file}"
  end

  desc "Generate session encryption keys"
  task secrets: :environment do
    file = Rails.root.join("config", "secrets.yml")
    if File.exist? file
      abort "#{file} exists, aborting"
    end
    puts "Generating #{file}"
    secrets = {
      "development" => {
        "secret_key_base" => SecureRandom.hex(64)
      },
      "production" => {
        "secret_key_base" => SecureRandom.hex(64)
      },
      "test" => {
        "secret_key_base" => SecureRandom.hex(64)
      }
    }
    File.open(file, "w") do |f|
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
    @location ||= Rails.root.join("db", "isk_database_backup-#{Time.now.strftime("%F-%H%M")}.sql")
  end

  def with_config
    yield Rails.application.class.parent_name.underscore,
    ActiveRecord::Base.connection_config[:host],
    ActiveRecord::Base.connection_config[:database],
    ActiveRecord::Base.connection_config[:username]
  end
end
