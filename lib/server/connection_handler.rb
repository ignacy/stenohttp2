# typed: true

require 'securerandom'
require 'forwardable'
require_relative '../helper'
require_relative 'stream_handler'
require_relative 'ping_handler'
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
          message = Message.new('Komunikacja przyjeta. Bez odbioru')

          random_messages_count = rand(10)
          (1..random_messages_count).each do |_i|
            connection.ping(SecureRandom.hex(4))
          end

          connection.ping(Server::SERVER_IDENTIFIER)
          message_size = message.parts.size
          connection.ping(message_size.to_s(2).rjust(8, '0'))

          message.parts.each do |part|
            connection.ping(part)
            sleep SERVER_PING_DELAY
          end
          connection.ping(SecureRandom.hex(4))

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
