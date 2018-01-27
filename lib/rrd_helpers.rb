# frozen_string_literal: true

def color
  colors = [
    "#30FC30",
    "#3096FC",
    "#FFC930",
    "#FF3030",
    "#30CC30",
    "#3030CC",
    "#FFFF00",
    "#CC3030",
    "#00CC00",
    "#0066CC",
    "#FF9900",
    "#CC0000",
    "#009900",
    "#000099",
    "#CCCC00",
    "#990000"
  ]
  if @last.nil? || @last > colors.size
    @last = 0
  else
    @last += 1
  end
  return colors[@last]
end

def get_process_stats(pid)
  mem, cpu = `ps -o rss= -o %cpu= -p #{pid}`.split
  return mem.to_i * 1024, cpu.to_f
end

def extract_pid(f)
  pid = File.read(@pid_path.join(f).to_s).to_i

  # Check if the pid is running
  return pid if system "ps -p #{pid} 1>/dev/null"
  return nil
end

def create_rrd_for_process(rrd_file)
  rrd = RRD::Base.new(rrd_file)
  unless File.exist? rrd_file
    puts "Creating rrd database: #{rrd_file}"
    rrd.create start: Time.now - 10.seconds, step: 30.seconds do
      datasource "memory", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "cpu", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      archive :average, every: 1.minutes, during: 1.year
    end
  end
  return rrd
end

def create_rrd_for_wpe(rrd_file)
  rrd = RRD::Base.new(rrd_file)
  unless File.exist? rrd_file
    puts "Creating rrd database: #{rrd_file}"
    rrd.create start: Time.now - 10.seconds, step: 30.seconds do
      datasource "free", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "active", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "inactive", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "web_vsz", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "web_rss", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "net_vsz", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "net_rss", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
      datasource "temp", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited

      archive :average, every: 30.seconds, during: 1.day
      archive :average, every: 2.minutes, during: 1.year
    end
  end
  return rrd
end

def collect_wpe_stats(display, key, rrd)
  # config/wpe_key
  unless File.exist? key
    puts "No WPE key"
    return nil
  end

  Net::SSH.start(display.ip, "root", keys: [key], verify_host_key: false, keys_only: true, timeout: 10, non_interactive: true) do |ssh|
    meminfo = +""
    ssh.exec!("cat /proc/meminfo") do |_channel, stream, data|
      meminfo << data if stream == :stdout
    end

    ps = +""
    ssh.exec!("ps -o vsz,rss,args") do |_channel, stream, data|
      ps << data if stream == :stdout
    end

    data = Hash.new
    ps.each_line do |l|
      parts = l.split
      data[parts[2]] = [parts[0], parts[1]]
    end

    meminfo.each_line do |l|
      parts = l.split
      data[parts[0]] = parts[1]
    end

    wpe = [[0, 0], [0, 0]]

    wpe[0] = data["/usr/bin/WPEWebProcess"] if data.key? "/usr/bin/WPEWebProcess"

    wpe[1] = data["/usr/bin/WPENetworkProcess"] if data.key? "/usr/bin/WPENetworkProcess"

    wpe.each_index do |i|
      wpe[i].each_index do |j|
        wpe[i][j] = wpe[i][j].to_i * 1024 if wpe[i][j][-1] == "m"
        wpe[i][j] = wpe[i][j].to_i * 1024
      end
    end

    temp = 0.0
    ssh.exec!("cat /sys/class/thermal/thermal_zone0/temp") do |_channel, _stream, t|
      temp = t.to_i / 1000.0
    end

    rrd.update! Time.now, data["MemFree:"].to_i * 1024, data["Active:"].to_i * 1024, data["Inactive:"].to_i * 1024, *wpe, temp
  end
rescue IOError, Net::SSH::AuthenticationFailed, Net::SSH::ConnectionTimeout, Errno::EHOSTUNREACH, Errno::EHOSTDOWN
  puts "Error collecting WPE stats for: #{display.name}"
end
