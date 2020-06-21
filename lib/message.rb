# typed: true

require_relative 'protocol'

class Message
  def initialize(content)
    @encoded = Protocol.new.encode(content)
  end

  def parts
    compress(@encoded)
  end

  def compress(text)
    text.chars.each_slice(8).to_a.map(&:join).map { |r| r.ljust(8) }
  end

  attr_reader :encoded
end
