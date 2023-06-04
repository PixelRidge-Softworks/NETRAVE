require 'curses'
require 'yaml'
require_relative 'utilities.rb'

class SystemInformationGather
  include Utilities

  def ask_for_uplink_speed
    while true
      Curses.clear
      Curses.setpos(2, 0)
      Curses.addstr("Please enter your uplink speed (upload speed, e.g., 1000Mbps or 1Gbps). ")
      Curses.addstr("This is typically the maximum upload speed provided by your ISP. ")
      Curses.addstr("You can check your ISP bill, use an online speed test, or contact your ISP if you're unsure. ")
      Curses.refresh
      speed = Curses.getstr.strip.downcase
      if valid_speed?(speed)
        return convert_speed_to_mbps(speed)
      else
        Curses.setpos(3, 0)
        Curses.addstr("Whoops! That didn't appear to be a valid speed. Please try again!")
        Curses.refresh
      end
    end
  end

  def ask_for_downlink_speed
    while true
      Curses.clear
      Curses.setpos(4, 0)
      Curses.addstr("Please enter your downlink speed (download speed, e.g., 1000Mbps or 1Gbps). ")
      Curses.addstr("This is typically the maximum download speed provided by your ISP. ")
      Curses.addstr("You can check your ISP bill, use an online speed test, or contact your ISP if you're unsure. ")
      Curses.refresh
      speed = Curses.getstr.strip.downcase
      if valid_speed?(speed)
        return convert_speed_to_mbps(speed)
      else
        Curses.setpos(5, 0)
        Curses.addstr("Whoops! That didn't appear to be a valid speed. Please try again!")
        Curses.refresh
      end
    end
  end

  def valid_speed?(speed)
    speed.to_i > 0
  end

  def ask_for_services
    while true
      Curses.clear
      Curses.setpos(6, 0)
      Curses.addstr("Please enter the services the system should be aware of (e.g., webserver, database). ")
      Curses.addstr("Enter the services as a comma-separated list (e.g., webserver,database). ")
      Curses.refresh
      services = Curses.getstr.strip.downcase.split(',').map(&:strip)
      if valid_services?(services)
        return services_to_hash(services)
      else
        Curses.setpos(7, 0)
        Curses.addstr("Whoops! That didn't appear to be a valid list of services. Please try again!")
        Curses.refresh
      end
    end
  end

  def valid_services?(services)
    # TODO: Validate the services
    true
  end

  def services_to_hash(services)
    services_hash = {}
    services.each { |service| services_hash[service] = true }
    services_hash
  end

  def ask_for_db_details
    Curses.clear
    Curses.setpos(1, 0)
    Curses.addstr("Please enter your database username: ")
    Curses.refresh
    username = Curses.getstr.strip

    Curses.setpos(2, 0)
    Curses.addstr("Please enter your database password: ")
    Curses.refresh
    Curses.echo = false
    password = Curses.getstr.strip
    Curses.echo
    Curses.setpos(3, 0)
    Curses.addstr("Please enter your database name: ")
    Curses.refresh
    database = Curses.getstr.strip

    { username: username, password: password, database: database }
  end

  def write_db_details_to_config_file(db_details)
    File.open("config.yml", "w") do |file|
      file.write(db_details.to_yaml)
    end
  end
end