# typed: false

require 'spec_helper'

RSpec.describe Framer do
  let(:text) { ('01' * 32) + ('10' * 32) }
  it 'split binnary string to integers 64 bits wide' do
    expect(Framer.new.to_numbers(text)).to eq([6_148_914_691_236_517_205, 12_297_829_382_473_034_410])
  end

  it 'joins numbers into a binnary string' do
    numbers = [6_148_914_691_236_517_205, 12_297_829_382_473_034_410]
    expect(Framer.new.numbers_to_binary_string(numbers)).to eq(text)
  end
end
