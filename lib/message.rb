# typed: true

require_relative 'protocol'
require_relative 'compressor'
require_relative 'framer'

class Message
  def initialize(content)
    encoded = Protocol.new.encode(content)
    compressed = Compressor.compress(encoded)
    @numbers = Framer.new.to_numbers(compressed)
  end

  attr_reader :numbers
end
