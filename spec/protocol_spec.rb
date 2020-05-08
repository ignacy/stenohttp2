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

  it 'encode as huffman code ' do
    secret = 'Najlepsze kasztany sa na placu pigalle'
    encoded = subject.encode(secret)
 
    compressed = HuffmanCoder.encode(encoded).to_s

    expect(HuffmanCoder.decode(compressed).plaintext).to eq(encoded)
  end

  it 'should split message into 64bit numbers' do
    secret = 'Najlepsze kasztany sa na placu pigalle'
    encoded = subject.encode(secret)
 
    compressed = HuffmanCoder.encode(encoded).to_s

    numbers = to_numbers(compressed)

    binaries = to_binaries(numbers)

    expect(HuffmanCoder.decode(compressed).plaintext).to eq(encoded)
  end

  def to_numbers(string)
    numbers = []
    string.chars.each_slice(64) do |slice|
      numbers << slice.join.to_i(2)
    end
    numbers
  end

  def to_binaries(numbers)
    numbers.map { |n| n.to_s(2) }.join("")
  end
end
