# typed: true

require 'forwardable'
require_relative '../helper'

class ConnectionHandler
  extend Forwardable

  def_delegators :@connection, :receive

  def initialize(socket)
    @socket = socket
    @connection = HTTP2::Server.new
    @communication = File.open('server_channel', 'a')
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def setup
    connection.on(:frame) do |bytes|
      socket.is_a?(TCPSocket) ? socket.sendmsg(bytes) : socket.write(bytes)
    end

    connection.on(:frame_sent) do |frame|
      puts "Sent frame: #{frame.inspect}"
    end
    connection.on(:frame_received) do |frame|
      puts "Received frame: #{frame.inspect}"

      if frame[:type] == :ping
        payload = frame[:payload]
        communication.write(payload)
        communication.flush
        #connection.ping('33333333')
      end
    end

    connection.on(:stream) do |stream|
      StreamHandler.new(stream).setup
    end
    connection
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  class StreamHandler
    def initialize(stream)
      @stream = stream
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def setup
      log = Stenohttp2::Logger.new(stream.id)
      req = T.let({}, T.untyped)
      buffer = ''

      stream.on(:active) { log.info 'client opened new stream' }
      stream.on(:close)  { log.info 'stream closed' }

      stream.on(:headers) do |h|
        req = Hash[*h.flatten]
        log.info "request headers: #{h}"
      end

      stream.on(:data) do |d|
        log.info "payload chunk: <<#{d}>>"
        buffer << d
      end

      stream.on(:half_close) do
        log.info 'client closed its end of the stream'
        response = Response.new(stream)
        response.build

        # Stream data to show this works
        stream.data(response.content[0...5], end_stream: false)
        stream.data(response.content[5...-1])
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    private

    attr_reader :stream
  end

  class Response
    def initialize(stream)
      @content = File.read(File.join('public', 'index.html'))
      @stream = stream
    end

    # We need this to be writable :reek:Attribute
    attr_accessor :content

    def build
      stream.headers(
        {
          ':status' => '200',
          'content-length' => content.bytesize.to_s,
          'content-type' => 'text/html'
        },
        end_stream: false
      )
    end

    private

    attr_reader :stream
  end

  attr_reader :connection, :socket, :communication
end
