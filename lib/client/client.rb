# frozen_string_literal: true

# typed: true
require_relative '../stenohttp2/helper'

class Client
  def initialize(opts = {})
    @server_address = opts.fetch(:server_url) { 'http://localhost:8080' }
    @data = "MY random string"
  end

  def start
    setup_connection_handlers
    setup_stream_handlers
    log.info 'Sending HTTP 2.0 request'
    if head[':method'] == 'GET'
      stream.headers(head, end_stream: true)
    else
      stream.headers(head, end_stream: false)
      conn.ping('12132134')
      stream.data(@data)
    end

    while !socket.closed? && !socket.eof?
      data = socket.read_nonblock(1024)
      log.info "Received bytes: #{data.unpack("H*").first}"

      begin
        conn << data
      rescue StandardError => e
        log.info "#{e.class} exception: #{e.message} - closing socket."
        T.must(e.backtrace).each { |l| puts "\t" + l }
        socket.close
      end
    end
  end

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

  def head
    @head ||= {
      ':scheme' => server_uri.scheme,
      ':method' => (@data.nil? ? 'GET' : 'POST'),
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

 # Client.new.start
