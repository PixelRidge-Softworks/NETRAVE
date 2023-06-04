require_relative 'system_information_gather.rb'
require_relative '../utils/utilities'

class DatabaseManager
  def initialize
    @db = nil
    @info_gatherer = SystemInformationGather.new
  end

  def test_db_connection(db_details)
    begin
      connection_string = "mysql2://#{db_details[:username]}:#{db_details[:password]}@localhost/#{db_details[:database]}"
      @db = Sequel.connect(connection_string)
      # Try a simple query to test the connection
      @db.run "SELECT 1"
      true
    rescue Sequel::DatabaseConnectionError
      false
    ensure
      @db.disconnect if @db
    end
  end

  def create_system_info_table
    @db.create_table? :system_info do
      primary_key :id
      Integer :uplink_speed
      Integer :downlink_speed
      String :services, text: true
    end
  end

  def store_system_info
    system_info = @info_gatherer.gather_system_info
    system_info[:uplink_speed] = Utilities.convert_speed_to_mbps(system_info[:uplink_speed])
    system_info[:downlink_speed] = Utilities.convert_speed_to_mbps(system_info[:downlink_speed])
    system_info[:services] = Utilities.services_to_hash(system_info[:services])
    @db[:system_info].insert(system_info)
  end
end