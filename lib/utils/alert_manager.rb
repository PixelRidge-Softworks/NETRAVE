# frozen_string_literal: true

# Class for creating and displaying alerts in the Curses TUI. This class also manages a little bit of concurrency
# We use mutex for sync so we don't break Curses, as Curses isn't thread safe
class Alert
  attr_reader :message, :severity

  def initialize(message, severity)
    @message = message
    @severity = severity
    @curses_mutex = Mutex.new
  end

  def display
    @curses_mutex.synchronize do
      # Initialize color pairs
      Curses.start_color
      Curses.init_pair(1, Curses::COLOR_BLUE, Curses::COLOR_BLACK)  # Info
      Curses.init_pair(2, Curses::COLOR_RED, Curses::COLOR_BLACK)   # Error
      Curses.init_pair(3, Curses::COLOR_YELLOW, Curses::COLOR_BLACK) # Warning

      # Create a new window for the alert at the bottom of the screen
      alert_window = Curses::Window.new(1, Curses.cols, Curses.lines - 1, 0)

      # Set the color attribute based on the severity of the alert
      case @severity
      when :info
        alert_window.attron(Curses.color_pair(1) | Curses::A_NORMAL) # Blue color
      when :warning
        alert_window.attron(Curses.color_pair(3) | Curses::A_NORMAL) # Yellow color
      when :error
        alert_window.attron(Curses.color_pair(2) | Curses::A_NORMAL) # Red color
      end

      # Add the message to the window and refresh it to display the message
      alert_window.addstr(@message)
      alert_window.refresh

      # Create a new thread to handle the delay and clearing of the alert
      # This is done in a separate thread to prevent the entire program from
      # pausing while the alert is displayed
      Thread.new do
        sleep(5) # Pause for 5 seconds

        # Clear the alert
        alert_window.clear
        alert_window.refresh
        alert_window.close
      end
    end
  end
end
