# typed: true

module Stenohttp2
  module Common
    class Message
      SIZE = 8

      def initialize(content, protocol = Protocol)
        @encoded = protocol.new.encode(content)
      end

      def parts
        compress encoded
      end

      def compress(text)
        text.chars.each_slice(SIZE).to_a.map(&:join).map { |r| r.ljust(SIZE) }
      end

      attr_reader :encoded
    end
  end
end
