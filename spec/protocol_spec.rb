# typed: false

require 'spec_helper'

RSpec.describe Protocol do
  subject { described_class.new }

  it 'encodes the message' do
    expect(subject.encode('hello')).to_not eq('hello')
  end

  it 'encodes and decodes the message' do
    secret = 'Najlepsze kasztany sa na placu pigalle'
    encoded = subject.encode(secret)
    expect(encoded).to_not eq(secret)
    expect(subject.decode(encoded)).to eq(secret)
  end

  it 'encode as binary code ' do
    secret = 'Najlepsze kasztany sa na placu pigalle'
    encoded = subject.encode(secret)

    compressed = Compressor.compress(encoded)
    expect(Compressor.decompress(compressed)).to eq(encoded)
  end
end
