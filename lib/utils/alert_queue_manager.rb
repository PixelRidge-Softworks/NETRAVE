# frozen_string_literal: true

require_relative 'alert'
require_relative 'logg_man'

# Class for managing the queue of alerts. This class also manages a little bit of concurrency
# We use mutex for sync so we don't break Curses, as Curses isn't thread safe
class AlertQueueManager
  SHUTDOWN_SIGNAL = 'shutdown'

  def initialize(logger) # rubocop:disable Metrics/MethodLength
    @loggman = logger
    @alert_queue = []
    @shutdown = false
    @worker_thread = Thread.new do
      loop do
        if @alert_queue.empty?
          sleep(0.1) # Sleep for 100 milliseconds
          next
        end

        alert = pop_alert
        break if alert.message == SHUTDOWN_SIGNAL

        alert.display
        sleep(4.5)
      end
    end
  end

  def enqueue_alert(alert)
    @alert_queue << alert
  end

  def pop_alert
    @alert_queue.shift
  end

  def shutdown
    enqueue_alert(Alert.new(SHUTDOWN_SIGNAL, :info))
    @shutdown = true
  end

  def join_worker
    @worker_thread.join if @shutdown
  end
end
