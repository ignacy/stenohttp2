# typed: true

require 'sorbet-runtime'

class Framer
  extend T::Sig

  sig { params(string: String).returns(T::Array[String]) }
  def to_numbers(string)
    numbers = []

    groups = to_bytesize(string, 8)

    groups.each do |slice|
      integer = slice.to_i(2)
      numbers << integer.to_s.rjust(8)
    end

    numbers
  end

  sig { params(numbers: T::Array[String]).returns(String) }
  def numbers_to_binary_string(numbers)
    T.must(numbers).map { |n| format('%0*b', 8, n) }.join
  end

  private

  sig { params(str: String, value: Integer).returns(T::Array[String]) }
  def to_bytesize(str, value = 8)
    str.unpack("a#{value}" * ((str.size / value) + (str.size % value > 0 ? 1 : 0)))
  end
end
