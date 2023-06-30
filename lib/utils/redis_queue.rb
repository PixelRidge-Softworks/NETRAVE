# frozen_string_literal: true

# Class for managing the worker queue in Redis
class RedisQueueManager
  def initialize(logger)
    @loggman = logger
  end
end
