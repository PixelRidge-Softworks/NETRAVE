require 'curses'
require 'yaml'
require_relative 'utilities.rb'
require_relative 'database_manager.rb'

class SystemInformationGather
  include Utilities

  def initialize(db_manager)
    @db_manager = db_manager
  end

  def gather_system_info
    uplink_speed = ask_for_uplink_speed
    downlink_speed = ask_for_downlink_speed
    services = ask_for_services

    total_bandwidth = uplink_speed + downlink_speed

    system_info = {
      uplink_speed: uplink_speed,
      downlink_speed: downlink_speed,
      total_bandwidth: total_bandwidth
    }

    # Check if the system_info table exists, if not, create it
    @db_manager.create_system_info_table unless @db_manager.table_exists?(:system_info)

    # Store the gathered system info in the database
    @db_manager.store_system_info(system_info)

    # Check if the services table exists, if not, create it
    @db_manager.create_services_table unless @db_manager.table_exists?(:services)

    # Store the services in the services table
    @db_manager.store_services(services)
  end

  def ask_for_uplink_speed
    while true
      Curses.clear
      Curses.setpos(2, 0)
      Curses.addstr("Please enter your uplink speed (upload speed, e.g., 1000Mbps or 1Gbps). ")
      Curses.addstr("This is typically the maximum upload speed provided by your ISP. ")
      Curses.addstr("You can check your ISP bill, use an online speed test, or contact your ISP if you're unsure. ")
      Curses.addstr(" ")
      Curses.setpos(5, 0)
      Curses.addstr("Uplink Speed: ")
      Curses.refresh
      speed = Curses.getstr.strip.downcase
      if valid_speed?(speed)
        return speed.end_with?('gbps') ? convert_speed_to_mbps(speed) : speed.to_i
      else
        Curses.setpos(5, 0)
        Curses.addstr("Whoops! That didn't appear to be a valid speed. Please try again!")
        Curses.refresh
      end
    end
  end
  
  def ask_for_downlink_speed
    while true
      Curses.clear
      Curses.setpos(2, 0)
      Curses.addstr("Please enter your downlink speed (download speed, e.g., 1000Mbps or 1Gbps). ")
      Curses.addstr("This is typically the maximum download speed provided by your ISP. ")
      Curses.addstr("You can check your ISP bill, use an online speed test, or contact your ISP if you're unsure. ")
      Curses.setpos(5, 0)
      Curses.addstr("Downlink Speed: ")
      Curses.refresh
      speed = Curses.getstr.strip.downcase
      if valid_speed?(speed)
        return speed.end_with?('gbps') ? convert_speed_to_mbps(speed) : speed.to_i
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
end