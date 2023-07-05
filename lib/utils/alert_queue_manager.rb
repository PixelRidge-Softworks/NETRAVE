# frozen_string_literal: true

require_relative 'ring_buffer'
# Class for managing the queues for alerts
class AlertQueueManager
  def initialize(logger, size = 2 * 1024 * 1024)
    @loggman = logger
    @queue = RingBuffer.new(@loggman, size)

    # Start a thread that continuously checks the queue and displays alerts
    @worker_thread = Thread.new do
      loop do
        alert = @queue.pop # This will block until there's an alert in the queue
        alert&.display
      end
    end
  end

  def enqueue_alert(alert)
    @queue.push(alert)
  end

  def join_worker
    @worker_thread.join
  end
end
