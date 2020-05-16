# typed: false

require 'spec_helper'

RSpec.describe 'Cupher encode and split the message and assemble + decode it' do
  let(:secret) { 'Najlepsze kasztany sa na placu pigalle' }

  it 'should split message into 8bits' do
    encoded = Protocol.new.encode(secret)
    compressed = Compressor.compress(encoded)
    numbers = Framer.new.to_numbers(compressed)

    # Numbers is what we send over the network...
    # And on the other side:
    binaries = Framer.new.numbers_to_binary_string(numbers)
    expect(binaries.size).to eq(compressed.size)
    decompressed = Compressor.decompress(binaries)
    expect(decompressed).to eq(encoded)

    message = Protocol.new.decode(decompressed)
    expect(message).to eq(secret)
  end
end
