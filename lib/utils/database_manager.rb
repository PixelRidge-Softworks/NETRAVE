# frozen_string_literal: true

require 'sequel'
require 'mysql2'
require_relative 'system_information_gather'
require_relative '../utils/utilities'

# database manager
class DatabaseManager
  include Utilities

  def initialize
    @db = nil
  end

  def test_db_connection(db_details)
    # Decrypt the password before using it
    decrypted_password = decrypt_string_chacha20(db_details[:password], db_details[:key])
    connection_string = "mysql2://#{db_details[:username]}:#{decrypted_password}@localhost/#{db_details[:database]}"
    @db = Sequel.connect(connection_string)
    # Try a simple query to test the connection
    @db.run 'SELECT 1'
    true
  rescue Sequel::DatabaseConnectionError
    false
  ensure
    @db&.disconnect
  end

  def create_system_info_table
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
