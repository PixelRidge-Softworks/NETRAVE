module Utilities
    # Converts speed from Gbps to Mbps if necessary
    def self.convert_speed_to_mbps(speed)
      if speed.end_with?('gbps')
        speed.to_i * 1000
      else
        speed.to_i
      end
    end
  
    # Converts an array of services into a hash
    def self.services_to_hash(services)
      services_hash = {}
      services.each { |service| services_hash[service] = true }
      services_hash
    end
  
    # Calculates total bandwidth from uplink and downlink speeds
    def self.calculate_total_bandwidth(uplink_speed, downlink_speed)
      uplink_speed + downlink_speed
    end
  end