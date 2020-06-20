# typed: true

class Compressor
  def self.compress(text)
    text.unpack1('b*')
  end

  def self.decompress(text)
    [text].pack('b*')
  end
end
