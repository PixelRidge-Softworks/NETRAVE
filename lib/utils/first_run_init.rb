require 'curses'
require_relative 'database_manager.rb'
require_relative 'system_information_gather.rb'
require_relative 'utilities.rb'

class FirstRunInit
  include Utilities

  def initialize(db_manager)
    @db_manager = db_manager
    @info_gatherer = SystemInformationGather.new(@db_manager)
  end

  def run
    first_run_setup
  end

  def first_run_setup
    db_details = ask_for_db_details
    while !@db_manager.test_db_connection(db_details)
      Curses.setpos(4, 0)
      Curses.addstr("Whoops! We couldn't connect to the database with the details you provided. Please try again!")
      Curses.refresh
      db_details = ask_for_db_details
    end
    @db_manager.create_system_info_table
    uplink_speed = @info_gatherer.ask_for_uplink_speed
    @db_manager.store_system_info(uplink_speed)
    downlink_speed = @info_gatherer.ask_for_downlink_speed
    @db_manager.store_system_info(downlink_speed)
    total_bandwidth = calculate_total_bandwidth(uplink_speed, downlink_speed)
    @db_manager.store_system_info(total_bandwidth)
    services = @info_gatherer.ask_for_services
    @db_manager.store_system_info(services)
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
    Curses.noecho
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

  def ask_for_default_mode
    while true
      Curses.setpos(8, 0)
      Curses.addstr("Please enter the default mode (TUI, GUI, or WebApp): ")
      Curses.refresh
      mode = Curses.getstr.strip.downcase
      if valid_mode?(mode)
        return mode
      else
        Curses.setpos(9, 0)
        Curses.addstr("Whoops! That didn't appear to be a valid mode. Please try again!")
        Curses.refresh
      end
    end
  end

  def valid_mode?(mode)
    ['tui', 'gui', 'webapp'].include?(mode)
  end
end
