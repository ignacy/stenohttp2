# typed: true

require_relative 'protocol'
require 'sorbet-runtime'

module Stenohttp2
  module Common
    class Message
      extend T::Sig
      SLICE_SIZE = 8

      sig { params(content: String, protocol: Protocol).void }
      def initialize(content, protocol = Protocol)
        @encoded = protocol.new.encode(content)
      end

      def parts
        compress encoded
      end

      def compress(text)
        text.chars.each_slice(SLICE_SIZE).to_a.map(&:join).map { |r| r.ljust(SLICE_SIZE) }
      end

      attr_reader :encoded
    end
  end
end
