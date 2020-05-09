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

      # TODO: problem jest jak ostatni wyraz zaczyna sie od zer
      # wtedy zrobienie mu paddingu rozwala kodowanie huffmana
      # bo było 001111
      # a my robimy 0000000000000000011111
      # Dlaczego zamiana pierwszej czy drugiej daje inna wartosc?
      # [1] pry(#<Framer>)> text.size
      # => 3
      # [2] pry(#<Framer>)> text.to_i(2)
      # => 3
      # [3] pry(#<Framer>)> text
      # => "011"
      # [4] pry(#<Framer>)> text = padd_string_to_64(text)
      # => "0000000000000000000000000000000000000000000000000000000000000011"
      # [5] pry(#<Framer>)> text.to_i(2)
      # => 3
      #if text != back
      #  raise "WTF? original: #{text} #{text.size}\nconverted: #{back} #{back.size}"
      # end
    end

    numbers
  end

  sig { params(numbers: T::Array[Integer]).returns(String) }
  def numbers_to_binary_string(numbers)
    out = numbers[0...-1].map { |n| format('%0*b', 64, n) }
    out << numbers.last.to_s(2)
    out.join('')
  end

  private

  sig { params(number: Integer).returns(String) }
  def number_to_padded_64_bit_binary(number)
    format('%b' % number)
  end

  sig { params(str: String).returns(String) }
  def remove_leading_zeros(str)
    str.sub(/^[0]+/, '')
  end
end
