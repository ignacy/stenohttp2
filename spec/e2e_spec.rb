# typed: false

require 'spec_helper'

RSpec.describe 'Cupher encode and split the message and assemble + decode it' do
  let(:secret) { 'Najlepsze kasztany sa na placu pigalle' }

  it 'should split message into 8bits' do
    encoded = Protocol.new.encode(secret)
    numbers = Compressor.compress(encoded)

    # Numbers is what we send over the network...
    # And on the other side:
    decompressed = Compressor.decompress(numbers)
    expect(decompressed).to eq(encoded)

    message = Protocol.new.decode(decompressed)
    expect(message).to eq(secret)
  end
end
