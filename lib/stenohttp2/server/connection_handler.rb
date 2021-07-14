# typed: true

require 'forwardable'

module Stenohttp2
  module Server
    class ConnectionHandler
      SERVER_PING_DELAY = 0.05
      extend Forwardable

      def_delegators :@connection, :receive

      def initialize(socket)
        @socket = socket
        @connection = HTTP2::Server.new
      end

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

          connection.on(:stream) { |s| StreamHandler.new(s).setup }
        end
      end

      private

      def ping_handler
        @ping_handler ||= PingHandler.new(server: true)
      end

      def response
        Message.new('message received.')
      end

      def sender(connection)
        Sender.new(
          message: response_message,
          connection: connection,
          identifier: Server::SERVER_IDENTIFIER,
          delay: SERVER_PING_DELAY
        )
      end

      attr_reader :connection, :socket
    end
  end
end
