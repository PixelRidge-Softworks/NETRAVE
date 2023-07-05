# frozen_string_literal: true

# Since the Standard Ruby library doesn't come with a Ring Buffer implementation, we need to make our own.
# this class creates a simple and rudementary implementation of a Ring Buffer for us to use.
class RingBuffer
  def initialize(logger, size)
    @loggman = logger
    @size = size
    @buffer = Array.new(size)
    @start = 0
    @end = 0
  end

  def push(element)
    @loggman.log_warn('Attempted to push to a full buffer. Overwriting old data.') if full?

    @buffer[@end] = element
    @end = (@end + 1) % @size
    @start = (@start + 1) % @size if @end == @start
  end

  def pop
    if empty?
      @loggman.log_warn('Attempted to pop from an empty buffer. Returning nil.')
      return nil
    end

    element = @buffer[@start]
    @start = (@start + 1) % @size
    element
  end

  def empty?
    @start == @end
  end

  def full?
    (@end + 1) % @size == @start
  end
end
