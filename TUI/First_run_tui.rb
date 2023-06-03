require 'curses'

def init_screen
  Curses.init_screen
  Curses.start_color
  # Define color pairs
  Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLUE) # Default
  Curses.init_pair(2, Curses::COLOR_RED, Curses::COLOR_BLUE)   # Alert
  Curses.init_pair(3, Curses::COLOR_BLACK, Curses::COLOR_RED)  # Emergent Alert
end

def first_run_setup
  # Ask for preferred color
  # TODO: Implement function to ask for color

  # Ask for uplink speed
  # TODO: Implement function to ask for uplink speed

  # Ask for total bandwidth
  # TODO: Implement function to ask for total bandwidth

  # Ask for services the system should be aware of
  # TODO: Implement function to ask for services

  # Ask for default mode
  # TODO: Implement function to ask for default mode
end

def main
  init_screen
  first_run_setup
  # TODO: Implement the rest of the program
ensure
  Curses.close_screen
end

main