# typed: ignore
require 'forwardable'
require 'http/2'

module Stenohttp2
  module Server
    class Handler
      SERVER_PING_DELAY = 0.05
      extend Forwardable
      def_delegators :@connection, :receive

      def initialize(socket)
        @socket = socket
        @connection = ::HTTP2::Server.new
      end

      # rubocop:disable Metrics/AbcSize
      def setup
        connection.tap do |connection|
          connection.on(:frame) do |bytes|
            socket.is_a?(TCPSocket) ? socket.sendmsg(bytes) : socket.write(bytes)
          end

          connection.on(:frame_received) do |frame|
            ping_handler.handle(frame[:payload]) if frame[:type] == :ping && !frame[:flags].include?(:ack)

            if ping_handler.send_response?
              sender(connection).call
              ping_handler.send_response = false
            end
          end

          connection.on(:stream) { |s| ::Stenohttp2::Server::StreamHandler.new(s).setup }
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def ping_handler
        @ping_handler ||= PingHandler.new(server: true)
      end

      def response_message
        ::Stenohttp2::Common::Message.new('message received.')
      end

      def sender(connection)
        ::Stenohttp2::Common::Sender.new(
          message: response_message,
          connection: connection,
          identifier: ENV.fetch('SERVER_IDENTIFIER'),
          delay: SERVER_PING_DELAY
        )
      end

      attr_reader :connection, :socket
    end
  end
end
