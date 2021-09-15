# typed: true

require_relative 'protocol'
require 'sorbet-runtime'

module Stenohttp2
  module Common
    class Message
      extend T::Sig
      SLICE_SIZE = 8 # Messages are split into chunks of length 8

      sig { params(content: String, protocol: T.class_of(Stenohttp2::Common::Protocol)).void }
      def initialize(content, protocol = Stenohttp2::Common::Protocol)
        @encoded = protocol.new.encode(content)
      end

      sig { returns(Array) }
      def parts
        compress(encoded)
      end

      sig { params(text: String).returns(Array) }
      def compress(text)
        text.chars.each_slice(SLICE_SIZE).to_a.map(&:join).map { |r| r.ljust(SLICE_SIZE) }
      end

      attr_reader :encoded
    end
  end
end
