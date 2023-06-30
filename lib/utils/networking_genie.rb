# frozen_string_literal: true

require 'socket'
require_relative 'logg_man'

# The class for setting up all the necessary system networking stuff for NETRAVE to work with without
# interferring with the rest of the system
class NetworkingGenie
  def initialize(logger)
    @loggman = logger
  end

  def find_main_interface # rubocop:disable Metrics/MethodLength
    @loggman.log_info('Identifying main network interface...')
    route_info = `routel`.split("\n")
    default_route = route_info.find { |line| line.include?('default') }
    if default_route
      main_interface = default_route.split.last
      @loggman.log_info("Main network interface identified: #{main_interface}")
      main_interface
    else
      @loggman.log_error('Failed to identify main network interface.')
      nil
    end
  rescue StandardError => e
    @loggman.log_error("Error occurred while identifying main network interface: #{e.message}")
    nil
  end

  def create_dummy_interface
    # TODO: Implement method to create a dummy network interface
  end

  def setup_traffic_mirroring
    # TODO: Implement method to set up traffic mirroring from the main interface to the dummy interface
  end
end
