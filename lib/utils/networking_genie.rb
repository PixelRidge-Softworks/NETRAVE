# frozen_string_literal: true

require 'English'
require 'socket'
require_relative 'logg_man'
require_relative 'alert'
require_relative 'alert_queue_manager'

# The class for setting up all the necessary system networking stuff for NETRAVE to work with without
# interferring with the rest of the system
class NetworkingGenie
  include Utilities

  def initialize(logger, alert_queue_manager)
    @loggman = logger
    @alert_queue_manager = alert_queue_manager
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

  def create_dummy_interface(interface_name = 'dummy0')
    # Check if the dummy module is loaded
    use_sudo('modprobe dummy')

    # Check if the interface already exists
    if `ip link show #{interface_name}`.empty?
      # Create the dummy interface
      use_sudo("ip link add #{interface_name} type dummy")

      # Set the interface up
      use_sudo("ip link set #{interface_name} up")
    else
      @loggman.log_info("Interface #{interface_name} already exists.")
      alert = Alert.new("Interface #{interface_name} already exists.", :info)
      @alert_queue_manager.enqueue_alert(alert)
    end
  end

  def setup_traffic_mirroring(main_interface, dummy_interface) # rubocop:disable Metrics/MethodLength
    commands = [
      "tc qdisc del dev #{main_interface} ingress",
      "tc qdisc add dev #{main_interface} handle ffff: ingress",
      "tc filter add dev #{main_interface} parent ffff: u32 match
       u32 0 0 action mirred egress mirror dev #{dummy_interface}"
    ]

    begin
      commands.each do |command|
        use_sudo(command)
      end
    rescue StandardError => e
      @loggman.log_error(e.message)
      alert = Alert.new(e.message, :error)
      @alert_queue_manager.enqueue_alert(alert)
    end
  end
end
