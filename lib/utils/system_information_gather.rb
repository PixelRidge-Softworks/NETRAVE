# frozen_string_literal: true

require 'curses'
require 'yaml'
require_relative 'utilities'
require_relative 'database_manager'
require 'dynamic_curses_input'

# gather system info
class SystemInformationGather
  include Utilities

  def initialize(db_manager, logger)
    @db_manager = db_manager
    @loggman = logger
  end

  def gather_system_info # rubocop:disable Metrics/MethodLength
    uplink_speed = ask_for_uplink_speed
    downlink_speed = ask_for_downlink_speed
    services = ask_for_services

    total_bandwidth = uplink_speed + downlink_speed

    system_info = {
      uplink_speed:,
      downlink_speed:,
      total_bandwidth:
    }

    @db_manager.create_system_info_table unless @db_manager.table_exists?(:system_info)
    @db_manager.store_system_info(system_info)

    @db_manager.create_services_table unless @db_manager.table_exists?(:services)
    @db_manager.store_services(services)
  end

  def ask_for_uplink_speed # rubocop:disable Metrics/MethodLength
    loop do
      Curses.clear
      Curses.addstr("Please enter your uplink speed (upload speed, e.g., 150Mbps or 1Gbps).\n" \
                    "This is typically the maximum upload speed provided by your ISP.\n" \
                    "You can check your ISP bill, use an online speed test, or contact your ISP if you're unsure.\n\n")
      Curses.refresh
      Curses.addstr('Uplink Speed: ')
      speed = DCI.catch_input(true)
      return convert_speed_to_mbps(speed) if valid_speed?(speed)

      Curses.setpos(5, 0)
      Curses.addstr("Whoops! That didn't appear to be a valid speed. Please try again!")
      Curses.refresh
    end
  end

  def ask_for_downlink_speed # rubocop:disable Metrics/MethodLength
    loop do
      Curses.clear
      Curses.addstr("Please enter your downlink speed (download speed, e.g., 1000Mbps or 1Gbps).\n" \
                    "This is typically the maximum download speed provided by your ISP.\n"\
                    "You can check your ISP bill, use an online speed test, or contact your ISP if you're unsure.\n\n")
      Curses.refresh
      Curses.addstr('Downlink Speed: ')
      speed = DCI.catch_input(true)
      return convert_speed_to_mbps(speed) if valid_speed?(speed)

      Curses.setpos(5, 0)
      Curses.addstr("Whoops! That didn't appear to be a valid speed. Please try again!")
      Curses.refresh
    end
  end

  def valid_speed?(speed)
    speed.to_i.positive? && speed.match?(/\A\d+(gbps|mbps)\z/i)
  end

  def ask_for_services # rubocop:disable Metrics/MethodLength
    loop do
      Curses.clear
      Curses.addstr("Please enter the services the system should be aware of (e.g., webserver or database).\n" \
                    "Enter the services as a comma-separated list (e.g., webserver,database).\n\n")
      Curses.refresh
      Curses.addstr('Services: ')
      services = DCI.catch_input(true)
      services_arr = services.strip.downcase.split(',').map(&:strip)

      return services_arr if valid_services?(services_arr)

      Curses.setpos(7, 0)
      Curses.addstr("Whoops! Thatdidn't appear to be a valid list of services. Please try again!")
      Curses.refresh
    end
  end

  def valid_services?(services)
    # TODO: Validate the services
    # For now, just check if the array is not empty
    !services.empty?
  end
end
