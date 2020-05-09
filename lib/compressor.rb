# typed: true

class Compressor
  def self.compress(text)
    # We can use HuffmanCoder here
    text.unpack1('b*')
  end

  def self.decompress(text)
    [text].pack('b*')
  end
end
