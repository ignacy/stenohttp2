# typed: false

require 'spec_helper'

RSpec.describe Compressor do

  it 'encode as binary code ' do
    secret = 'Najlepsze kasztany sa na placu pigalle'
    encoded = Protocol.new.encode(secret)

    compressed = Compressor.compress(encoded)
    expect(Compressor.decompress(compressed)).to eq(encoded)
  end
end
