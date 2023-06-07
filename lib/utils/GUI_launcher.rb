require 'gtk3'

class GUI_Launcher
  def initialize
    @app = Gtk::Application.new("com.netrave.gui", :flags_none)

    @app.signal_connect "activate" do |application|
      builder = Gtk::Builder.new
      builder.add_from_file("./Glade/NETRAVE.glade")

      window = builder.get_object("main_window")
      window.application = application

      screen = Gdk::Screen.default
      width = screen.width
      height = screen.height

      if width >= 3840 and height >= 2160
        # 4K resolution
        window.set_default_size(1200, 1000)
      elsif width >= 1920 and height >= 1080
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
    puts "Launching GUI..."
    @app.run
  end
end
