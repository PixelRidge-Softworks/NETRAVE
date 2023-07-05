# frozen_string_literal: true

require 'sequel'
require 'mysql2'
require_relative 'system_information_gather'
require_relative '../utils/utilities'

# database manager
class DatabaseManager
  include Utilities

  def initialize(logger, alert_queue_manager)
    @db = nil
    @loggman = logger
    @alert_queue_manager = alert_queue_manager
  end

  def test_db_connection(username, password, database) # rubocop:disable Metrics/MethodLength
    @loggman.log_info('Attempting to connect to the database...')

    # Create the connection string
    connection_string = "mysql2://#{username}:#{password}@localhost/#{database}"
    @db = Sequel.connect(connection_string)
    # Try a simple query to test the connection
    @db.run 'SELECT 1'

    @loggman.log_info('Successfully connected to the database.')
    alert = Alert.new('Successfully connected to the database.', :info)
    @alert_queue_manager.enqueue_alert(alert)
    true
  rescue Sequel::DatabaseConnectionError => e
    @loggman.log_error("Failed to connect to the database: #{e.message}")
    alert = Alert.new('Failed to connect to the database!', :error)
    @alert_queue_manager.enqueue_alert(alert)
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
        alert = Alert.new('Successfully connected to the database.')
        @alert_queue_manager.enqueue_alert(alert)
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

  def store_system_info(system_info) # rubocop:disable Metrics/MethodLength
    # Check if the system_info already exists in the database
    @loggman.log_info('Checking if info exists in the Database...')

    existing_system_info = @db[:system_info].where(uplink_speed: system_info[:uplink_speed],
                                                   downlink_speed: system_info[:downlink_speed],
                                                   total_bandwidth: system_info[:total_bandwidth]).first

    if existing_system_info
      # If it exists, update it
      @loggman.log_info('Info already exists. Updating instead of adding more data to the table...')

      @db[:system_info].where(id: existing_system_info[:id]).update(system_info)
    else
      # If it doesn't exist, insert it
      @loggman.log_info('Info does not exist already, inserting it...')

      @db[:system_info].insert(system_info)
    end
  end

  def create_services_table
    @db.create_table? :services do
      primary_key :id
      String :service_name
      TrueClass :status, default: true
    end
  end

  def store_services(services) # rubocop:disable Metrics/MethodLength
    services.each do |service|
      # Check if the service already exists in the database
      @loggman.log_info('Checking if info exists in the Database...')

      existing_service = @db[:services].where(service_name: service).first

      if existing_service
        # If it exists, update it
        @loggman.log_info('Info already exists, updating instead of adding more data to the table...')

        @db[:services].where(id: existing_service[:id]).update(service_name: service, status: true)
      else
        # If it doesn't exist, insert it
        @loggman.log_info('Info does not exist already, inserting it...')

        @db[:services].insert(service_name: service, status: true)
      end
    end
  end
end
