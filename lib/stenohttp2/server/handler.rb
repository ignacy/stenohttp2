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
        connection.on(:frame) do |bytes|
          socket.is_a?(TCPSocket) ? socket.sendmsg(bytes) : socket.write(bytes)
        end

        # Here is where the magic happens: we treat PING frames a bit
        # differently than in a usual flow, where those would be used only to
        # check stream/connection latency
        connection.on(:frame_received) do |frame|
          ping_handler.handle(frame[:payload]) if handle_frame?(frame)

          if ping_handler.responding?
            sender(connection).call
            ping_handler.done
          end
        end

        # We still want to handle streaming for regular communication, like
        # sending html content
        connection.on(:stream) { |s| ::Stenohttp2::Server::StreamHandler.new(s).setup }
        connection
      end
      # rubocop:enable Metrics/AbcSize

      private

      def ping_handler
        @ping_handler ||= ::Stenohttp2::Server::PingHandler.new(server: true)
      end

      # We are only interested in PING farmes without ACK flag
      # because the ones with ACK include just the repeated contend
      def handle_frame?(frame)
        frame[:type] == :ping && !frame[:flags].include?(:ack)
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
