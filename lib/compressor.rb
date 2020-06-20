# typed: true

class Compressor
  def self.compress(text)
    # S | An Unsigned Integer per 2 Bytes
    # text.unpack('s*')
    text.chars.each_slice(8).to_a.map(&:join).map { |r| r.ljust(8) }
  end

  def self.decompress(array)
    array.join.strip
  end
end
