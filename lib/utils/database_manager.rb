# frozen_string_literal: true

require 'sequel'
require 'mysql2'
require_relative 'system_information_gather'
require_relative '../utils/utilities'
require_relative 'logg_man'

# database manager
class DatabaseManager
  include Utilities

  def initialize
    @db = nil
    @loggman = LoggMan.new
  end

  def test_db_connection(username, password, database) # rubocop:disable Metrics/MethodLength
    loggman = LoggMan.new
    loggman.log_info('Attempting to connect to the database...')
    display_alert('Attempting to connect to the database...', :info)

    # Create the connection string
    connection_string = "mysql2://#{username}:#{password}@localhost/#{database}"
    @db = Sequel.connect(connection_string)
    # Try a simple query to test the connection
    @db.run 'SELECT 1'
    loggman.log_info('Successfully connected to the database.')
    display_alert('Successfully connected to the database.', :info)
    true
  rescue Sequel::DatabaseConnectionError => e
    loggman.log_error("Failed to connect to the database: #{e.message}")
    display_alert('Failed to connect to the database!', :error)
    false
  end

  def create_system_info_table # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    if @db.nil?
      # Attempt to establish a connection
      username = ENV['DB_USERNAME']
      password = decrypt_string_chacha20(ENV['DB_PASSWORD'], ENV['DB_SECRET_KEY'])
      database = ENV['DB_DATABASE']
      if test_db_connection(username, password, database)
        @loggman.log_info('Successfully connected to the database.')
        display_alert('Successfully connected to the Database1', :info)
      else
        # If the connection attempt fails, log an error and return
        @loggman.log_error('Failed to connect to the database.')
        return
      end
    end

    if @db.nil?
      @loggman.log_error('@db is still nil after attempting to connect to the database.')
      return
    end

    @db.create_table? :system_info do
      primary_key :id
      Integer :uplink_speed
      Integer :downlink_speed
      Integer :total_bandwidth
    end
  end

  def store_system_info(system_info)
    @db[:system_info].insert(system_info)
  end

  def create_services_table
    @db.create_table? :services do
      primary_key :id
      String :service_name
      TrueClass :status, default: true
    end
  end

  def store_services(services)
    services.each do |service|
      @db[:services].insert(service_name: service, status: true)
    end
  end
end
