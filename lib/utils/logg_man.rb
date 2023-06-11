# frozen_string_literal: true

require 'logger'

# LoggMan class for handling logs
class LoggMan
  def initialize
    @logger = Logger.new('netrave.log')
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
