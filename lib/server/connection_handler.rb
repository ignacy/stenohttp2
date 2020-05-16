# typed: true

require 'forwardable'
require_relative '../helper'
require_relative 'stream_handler'
require_relative 'ping_handler'

class ConnectionHandler
  extend Forwardable

  def_delegators :@connection, :receive

  def initialize(socket)
    @socket = socket
    @connection = HTTP2::Server.new
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def setup
    connection.tap do |connection|
      connection.on(:frame) do |bytes|
        socket.is_a?(TCPSocket) ? socket.sendmsg(bytes) : socket.write(bytes)
      end

      connection.on(:frame_received) do |frame|
        ping_handler.handle(frame[:payload]) if frame[:type] == :ping
      end

      connection.on(:stream) do |stream|
        StreamHandler.new(stream).setup
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def ping_handler
    @ping_handler ||= PingHandler.new(server: true)
  end

  attr_reader :connection, :socket
end
