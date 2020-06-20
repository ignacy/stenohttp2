# typed: true

require_relative 'protocol'
require_relative 'compressor'

class Message
  def initialize(content)
    encoded = Protocol.new.encode(content)
    @parts = Compressor.compress(encoded)
  end

  attr_reader :parts
end
