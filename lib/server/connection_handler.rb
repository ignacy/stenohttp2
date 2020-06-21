# typed: true

require 'forwardable'
require_relative '../helper'
require_relative 'stream_handler'
require_relative 'ping_handler'
require_relative '../sender'
require_relative '../message'
require_relative './server'

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
          Sender.new(
            message: Message.new('Komunikacja przyjeta. Bez odbioru'),
            connection: connection,
            identifier: Server::SERVER_IDENTIFIER,
            delay: SERVER_PING_DELAY
          ).call
          ping_handler.send_response = false
        end
      end

      connection.on(:stream) do |stream|
        StreamHandler.new(stream).setup
      end
    end
  end
  # rubocop:enable

  private

  def ping_handler
    @ping_handler ||= PingHandler.new(server: true)
  end

  attr_reader :connection, :socket
end
