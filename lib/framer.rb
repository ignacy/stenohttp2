# typed: true

require 'sorbet-runtime'

class Framer
  extend T::Sig

  sig { params(string: String).returns(T::Array[Integer]) }
  def to_numbers(string)
    numbers = []
    groups = string.chars.each_slice(64).to_a

    groups.each do |slice|
      text = slice.join
      integer = text.to_i(2)
      numbers << integer
    end

    numbers
  end

  sig { params(numbers: T::Array[Integer]).returns(String) }
  def numbers_to_binary_string(numbers)
    out = T.must(numbers[0...-1]).map { |n| format('%0*b', 64, n) }
    out << numbers.last.to_s(2) # last one is not padded
    out.join('')
  end
end
