# frozen_string_literal: true

require 'gtk3'

# GUI launcher
class GUILauncher
  def initialize # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @app = Gtk::Application.new('com.netrave.gui', :flags_none)

    @app.signal_connect 'activate' do |application|
      builder = Gtk::Builder.new
      builder.add_from_file('./Glade/NETRAVE.glade')

      window = builder.get_object('main_window')
      window.application = application

      screen = Gdk::Screen.default
      width = screen.width
      height = screen.height

      if (width >= 3840) && (height >= 2160)
        # 4K resolution
        window.set_default_size(1200, 1000)
      elsif (width >= 1920) && (height >= 1080)
        # 1080p resolution
        window.set_default_size(1080, 800)
      else
        # 720p or lower resolution
        window.set_default_size(800, 600)
      end

      window.show_all
    end
  end

  def run
    puts 'Launching GUI...'
    @app.run
  end
end
