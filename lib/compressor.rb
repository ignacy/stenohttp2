# typed: true

class Compressor
  def self.compress(text)
    # Q | An Unsigned Integer per 8 Bytes
    text.unpack("Q*")
  end

  def self.decompress(numbers)
    numbers.pack('Q*')
  end
end
