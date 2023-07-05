# frozen_string_literal: true

require_relative 'ring_buffer'
# Class for managing the queues for alerts
class AlertQueueManager
  SHUTDOWN_SIGNAL = 'shutdown'

  def initialize(logger, size = 2 * 1024 * 1024) # rubocop:disable Metrics/MethodLength
    @loggman = logger
    @queue = RingBuffer.new(@loggman, size)
    @shutdown = false

    # Start a thread that continuously checks the queue and displays alerts
    @worker_thread = Thread.new do
      loop do
        break if @shutdown && @queue.empty?

        if @queue.empty?
          sleep(0.1) # Sleep for 100 milliseconds
          next
        end

        alert = @queue.pop # This will block until there's an alert in the queue
        next if alert.nil?

        break if alert.message == SHUTDOWN_SIGNAL

        alert.display
        sleep(4.5)
        alert.clear
      end
    end
  end

  def enqueue_alert(alert)
    return if @shutdown

    @queue.push(alert)
  end

  def shutdown
    @shutdown = true
    enqueue_alert(Alert.new(SHUTDOWN_SIGNAL, :info))
  end
end
