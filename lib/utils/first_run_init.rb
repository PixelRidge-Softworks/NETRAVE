# frozen_string_literal: true

require 'curses'
require 'dynamic_curses_input'
require 'dotenv'
require_relative 'database_manager'
require_relative 'system_information_gather'
require_relative 'utilities'
require_relative 'logg_man'

# first run class
class FirstRunInit
  include Utilities
  include Curses

  def initialize(db_manager = nil)
    @db_manager = db_manager || DatabaseManager.new
    @info_gatherer = SystemInformationGather.new(@db_manager)
    @loggman = LoggMan.new
    Dotenv.load
  end

  def run
    first_run_setup
  end

  def first_run_setup # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    db_details = ask_for_db_details

    enc_pass = ENV['DB_PASSWORD']
    enc_key = ENV['DB_SECRET_KEY']
    dec_pass = decrypt_string_chacha20(enc_pass, enc_key)
    until @db_manager.test_db_connection(ENV['DB_USERNAME'], dec_pass.to_s, ENV['DB_DATABASE'])
      Curses.setpos(4, 0)
      Curses.addstr("Whoops! We couldn't connect to the database with the details you provided. Please try again!")
      Curses.refresh
      new_db_details = ask_for_db_details
      db_details.merge!(new_db_details) # Update db_details with new details
    end

    @db_manager.create_system_info_table
    @db_manager.create_services_table

    uplink_speed = @info_gatherer.ask_for_uplink_speed
    downlink_speed = @info_gatherer.ask_for_downlink_speed
    total_bandwidth = calculate_total_bandwidth(uplink_speed, downlink_speed)
    services = @info_gatherer.ask_for_services

    system_info = {
      uplink_speed:,
      downlink_speed:,
      total_bandwidth:
    }

    @db_manager.store_system_info(system_info)
    @db_manager.store_services(services)
  end

  def ask_for_db_details # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    Curses.clear

    Curses.setpos(1, 0)
    Curses.addstr('Please enter your database username: ')
    Curses.refresh
    username = DCI.catch_input(true)

    Curses.setpos(2, 0)
    Curses.addstr('Please enter your database password: ')
    Curses.refresh
    Curses.noecho
    password = DCI.catch_input(false)
    Curses.echo

    Curses.setpos(3, 0)
    Curses.addstr('Please enter your database name: ')
    Curses.refresh
    database = DCI.catch_input(true)

    # Generate a secret key
    key = generate_key

    # Encrypt the password
    encrypted_password = encrypt_string_chacha20(password, key)

    db_details = { username:, password: encrypted_password, key:, database: }
    write_db_details_to_config_file(db_details)
  end

  def write_db_details_to_config_file(db_details)
    # Write the database details to the .env file
    File.open('.env', 'w') do |file|
      file.puts %(DB_USERNAME="#{db_details[:username]}")
      file.puts %(DB_PASSWORD="#{db_details[:password]}")
      file.puts %(DB_SECRET_KEY="#{db_details[:key]}")
      file.puts %(DB_DATABASE="#{db_details[:database]}")
    end

    # Load the .env file using dotenv
    Dotenv.load
  rescue StandardError => e
    @loggman.log_error("Failed to write to .env file: #{e.message}")
  end

  def ask_for_default_mode
    loop do
      Curses.setpos(8, 0)
      Curses.addstr('Please enter the default mode (TUI, GUI, or WebApp): ')
      Curses.refresh
      mode = Curses.getstr.strip.downcase
      return mode if valid_mode?(mode)

      Curses.setpos(9, 0)
      Curses.addstr("Whoops! That didn't appear to be a valid mode. Please try again!")
      Curses.refresh
    end
  end

  def valid_mode?(mode)
    %w[tui gui webapp].include?(mode)
  end
end
