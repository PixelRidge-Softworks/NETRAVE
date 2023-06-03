require 'curses'

def first_run_setup
  color = ask_for_color
  # TODO: Use the color for something
  db_details = ask_for_db_details
  while !test_db_connection(db_details)
    Curses.setpos(4, 0)
    Curses.addstr("Whoops! We couldn't connect to the database with the details you provided. Please try again!")
    Curses.refresh
    db_details = ask_for_db_details
  end
  uplink_speed = ask_for_uplink_speed
  # TODO: Use the uplink speed for something
  downlink_speed = ask_for_downlink_speed
  # TODO: Use the downlink speed for something
  total_bandwidth = calculate_total_bandwidth(uplink_speed, downlink_speed)
  # TODO: Use the total bandwidth for something
  services = ask_for_services
  # TODO: Use the services for something
  # ...
end

def ask_for_color
  while true
    Curses.clear
    Curses.setpos(0, 0)
    Curses.addstr("Please enter your preferred color (white, red, or black): ")
    Curses.refresh
    color = Curses.getstr.strip.downcase
    if ['white', 'red', 'black'].include?(color)
      return color
    else
      Curses.setpos(1, 0)
      Curses.addstr("Whoops! That didn't appear to be a valid color. Please try again!")
      Curses.refresh
    end
  end
end

def ask_for_default_mode
  while true
    Curses.setpos(8, 0)
    Curses.addstr("Please enter the default mode (TUI, GUI, or WebApp): ")
    Curses.refresh
    mode = Curses.getstr.strip.downcase
    if valid_mode?(mode)
      return mode
    else
      Curses.setpos(9, 0)
      Curses.addstr("Whoops! That didn't appear to be a valid mode. Please try again!")
      Curses.refresh
    end
  end
end

def valid_mode?(mode)
  ['tui', 'gui', 'webapp'].include?(mode)
end
