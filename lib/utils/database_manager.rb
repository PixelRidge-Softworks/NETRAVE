class DatabaseManager
    def initialize
      @db = nil
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
  end
  