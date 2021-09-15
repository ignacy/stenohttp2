# typed: ignore
# frozen_string_literal: true

require 'securerandom'
require 'http/2'

# rubocop:disable Metrics/ClassLength
module Stenohttp2
  module Client
    class Client
      CLIENT_PING_DELAY = 0.1
      CLIENT_IDENTIFIER = 'ccxin6f5'

      def initialize(opts = {})
        @server_address = opts.fetch(:server_url, 'https://localhost:8080')
        @data = 'MY random string'
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def start
        setup_connection_handlers
        setup_stream_handlers
        log.info 'Sending HTTP 2.0 request'

        stream.headers(get_request, end_stream: false) # GET data
        pinger = Thread.new do
          loop do
            conn.ping(SecureRandom.hex(4))
            sleep CLIENT_PING_DELAY
          end
        end

        Thread.kill(pinger)

        Sender.new(
          message: Message.new('Witaj świecie. Tajne dane: płatki owsiane, banan, orechy włoskie, jabłko'),
          connection: conn,
          identifier: CLIENT_IDENTIFIER,
          delay: CLIENT_PING_DELAY
        ).call

        pinger = Thread.new do
          loop do
            conn.ping(SecureRandom.hex(4))
            sleep CLIENT_PING_DELAY
          end
        end

        stream.headers(post_request, end_stream: false) # POST data
        stream.data(@data)

        Thread.kill(pinger)
        while !socket.closed? && !socket.eof?
          data = socket.read_nonblock(1024)
          log.info "Received bytes: #{data.unpack1('H*')}"

          begin
            conn << data
          rescue StandardError => e
            log.info "#{e.class} exception: #{e.message} - closing socket."
            e.backtrace.each { |l| puts "\t#{l}" }
            socket.close
          end
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def setup_connection_handlers
        conn.on(:frame) do |bytes|
          socket.is_a?(TCPSocket) ? socket.sendmsg(bytes) : socket.write(bytes)
        end

        conn.on(:frame_received) do |frame|
          ping_handler.handle(frame[:payload]) if frame[:type] == :ping && !frame[:flags].include?(:ack)
        end
      end

      def setup_stream_handlers
        stream.on(:close) do
          log.info 'stream closed'
        end

        stream.on(:headers) do |h|
          log.info "response headers: #{h}"
        end

        stream.on(:data) do |d|
          log.info "response data chunk: <<#{d}>>"
        end
      end

      private

      attr_reader :server_address

      def server_uri
        @server_uri ||= URI.parse(server_address)
      end

      def ping_handler
        @ping_handler ||= PingHandler.new(server: false)
      end

      # rubocop:disable Metrics/AbcSize
      def socket
        @socket ||= begin
          tcp = TCPSocket.new(server_uri.host, server_uri.port)

          if server_uri.scheme == 'https'
            ctx = OpenSSL::SSL::SSLContext.new
            ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
            ctx.alpn_protocols = [DRAFT]
            ctx.alpn_select_cb = lambda do |protocols|
              log.warn "ALPN protocols supported by server: #{protocols}"
              DRAFT if protocols.include? DRAFT
            end

            sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
            sock.sync_close = true
            sock.hostname = server_uri.hostname
            sock.connect

            raise "Failed to negotiate #{DRAFT} via ALPN" if sock.alpn_protocol != DRAFT

            sock
          else
            tcp
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Naming/AccessorMethodName
      def get_request
        @get_request ||= {
          ':scheme' => server_uri.scheme,
          ':method' => 'GET',
          ':authority' => [server_uri.host, server_uri.port].join(':'),
          ':path' => server_uri.path,
          'accept' => '*/*'
        }
      end
      # rubocop:enable Naming/AccessorMethodName

      def post_request
        @post_request ||= {
          ':scheme' => server_uri.scheme,
          ':method' => 'POST',
          ':authority' => [server_uri.host, server_uri.port].join(':'),
          ':path' => server_uri.path,
          'accept' => '*/*'
        }
      end

      def conn
        @conn ||= HTTP2::Client.new
      end

      def stream
        @stream ||= conn.new_stream
      end

      def log
        @log ||= Stenohttp2::Logger.new(stream.id)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
