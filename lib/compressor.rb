# typed: true

class Compressor
  def self.compress(text)
    # S | An Unsigned Integer per 2 Bytes
    text.unpack('s*')
  end

  def self.decompress(numbers)
    numbers.pack('s*')
  end
end
