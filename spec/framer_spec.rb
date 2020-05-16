# typed: false

require 'spec_helper'

RSpec.describe Framer do
  let(:text) { '11111111' + '00000001' }

  it 'split binnary string to left padded integer streams of size 8' do
    expect(Framer.new.to_numbers(text)).to eq(['     255', '       1'])
  end

  it 'joins numbers into a binnary string' do
    numbers = ['255', '1']
    expect(Framer.new.numbers_to_binary_string(numbers)).to eq(text)
  end
end
