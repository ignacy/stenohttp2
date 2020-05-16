# frozen_string_literal: true

# typed: true
require_relative '../helper'
require_relative '../message'

# rubocop:disable Metrics/ClassLength
class Client
  def initialize(opts = {})
    @server_address = opts.fetch(:server_url) { 'https://localhost:8080' }
    @data = 'MY random string'
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def start
    setup_connection_handlers
    setup_stream_handlers
    log.info 'Sending HTTP 2.0 request'

    puts 'DOING GET'
    stream.headers(get_request, end_stream: false)

    message = Message.new('Witaj świecie. Tajne dane: płatki owsiane, banan, orechy włoskie, jabłko')
    message.numbers.each do |number|
      puts "SENDING #{number}"
      conn.ping(number.to_s)
    end

    puts 'DOING POST'
    stream.headers(post_request, end_stream: false)
    stream.data(@data)

    while !socket.closed? && !socket.eof?
      data = socket.read_nonblock(1024)
      log.info "Received bytes: #{data.unpack1('H*')}"

      begin
        conn << data
      rescue StandardError => e
        log.info "#{e.class} exception: #{e.message} - closing socket."
        T.must(e.backtrace).each { |l| puts "\t" + l }
        socket.close
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def setup_connection_handlers
    conn.on(:frame) do |bytes|
      # puts "Sending bytes: #{bytes.unpack("H*").first}"
      socket.print bytes
      socket.flush
    end
    conn.on(:frame_sent) do |frame|
      log.info "Sent frame: #{frame.inspect}"
    end
    conn.on(:frame_received) do |frame|
      log.info "Received frame: #{frame.inspect}"
    end

    conn.on(:promise) do |promise|
      promise.on(:promise_headers) do |h|
        log.info "promise request headers: #{h}"
      end

      promise.on(:headers) do |h|
        log.info "promise headers: #{h}"
      end

      promise.on(:data) do |d|
        log.info "promise data chunk: <<#{d.size}>>"
      end
    end

    conn.on(:altsvc) do |f|
      log.info "received ALTSVC #{f}"
    end
  end

  def setup_stream_handlers
    stream.on(:close) do
      log.info 'stream closed'
    end

    stream.on(:half_close) do
      log.info 'closing client-end of the stream'
    end

    stream.on(:headers) do |h|
      log.info "response headers: #{h}"
    end

    stream.on(:data) do |d|
      log.info "response data chunk: <<#{d}>>"
    end

    stream.on(:altsvc) do |f|
      log.info "received ALTSVC #{f}"
    end
  end

  private

  attr_reader :server_address

  def server_uri
    @server_uri ||= URI.parse(server_address)
  end

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

                    if sock.alpn_protocol != DRAFT
                      raise "Failed to negotiate #{DRAFT} via ALPN"
                    end

                    sock
                  else
                    tcp
                  end
                end
  end

  def get_request
    @get_request ||= {
      ':scheme' => server_uri.scheme,
      ':method' => 'GET',
      ':authority' => [server_uri.host, server_uri.port].join(':'),
      ':path' => server_uri.path,
      'accept' => '*/*'
    }
  end

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
# rubocop:enable Metrics/ClassLength
