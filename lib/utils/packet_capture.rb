# frozen_string_literal: true

require 'pcaprub'
require 'socket'
require_relative 'databasemanager'
require_relative 'logg_man'
require_relative 'redis_queue'

# Class used to capture packets and not much else
class PacketCapture
  INTERFACE_NAME = 'netrave0'

  def initialize(queue, logger)
    @loggman = logger
    @loggman.log_info("Initializing packet capture for #{INTERFACE_NAME}...")
    @capture = Pcap.open_live(INTERFACE_NAME, 65_535, true, 1)
    @capture.setfilter('')
    @loggman.log_info('Packet capture initialized successfully!')
    @queue = queue
  end

  def start_capture_loop # rubocop:disable Metrics/MethodLength
    @loggman.log_info("Starting packet capture loop for #{@interface}...")
    packet_count = 0
    begin
      @loggman.log_info("Packet capture loop started for #{@interface}...")
      @capture.each_packet do |packet|
        # Add packet to queue
        @queue.push(packet)
        @loggman.log_info("Packet #{packet_count += 1} added to queue.")
      end
    rescue StopIteration
      @loggman.log_warn("Packet capture loop stopped for #{@interface}.")
    rescue StandardError => e
      @loggman.log_fatal("Packet capture loop stopped for #{@interface}: #{e.message}\n#{e.backtrace}", false)
      sleep 1
      retry
    ensure
      @capture.close
    end
  end

  def stop_capture
    @loggman.log_warn("Stopping packet capture loop for #{@interface}...")
    @stop_flag = true
  end
end
