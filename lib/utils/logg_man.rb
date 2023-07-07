# frozen_string_literal: true

require 'logger'

# LoggMan class for handling logs
# Yes I am aware that this is a strange thing to do,  wrap the stdlib Logger like this...
# I like to call my logger with LoggMan, don't judge me.
class LoggMan
  def initialize
    @logger = Logger.new('netrave.log')
    @logger.formatter = proc do |severity, datetime, _progname, msg|
      date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
      if msg.is_a?(Exception)
        backtrace = msg.backtrace.map { |line| "\n\t#{line}" }.join
        "[#{severity}] (#{date_format}) #{msg.message} (#{msg.class})#{backtrace}"
      else
        "[#{severity}] (#{date_format}) #{msg}\n"
      end
    end
  end

  def log_info(message)
    @logger.info(message)
  end

  def log_error(message)
    @logger.error(message)
  end

  def log_warn(message)
    @logger.warn(message)
  end

  def log_debug(message)
    @logger.debug(message)
  end

  def log_fatal(message)
    @logger.fatal(message)
  end
end
