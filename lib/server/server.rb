# frozen_string_literal: true

# typed: true

require_relative '../stenohttp2/helper'

class Server
  def initialize(opts = {})
    @port = opts.fetch(:port) { 8080 }
  end

  def start
    loop do
      sock = server.accept
      puts 'New TCP connection!'

      conn = HTTP2::Server.new
      conn.on(:frame) do |bytes|
        # puts "Writing bytes: #{bytes.unpack("H*").first}"
        sock.is_a?(TCPSocket) ? sock.sendmsg(bytes) : sock.write(bytes)
      end
      conn.on(:frame_sent) do |frame|
        puts "Sent frame: #{frame.inspect}"
      end
      conn.on(:frame_received) do |frame|
        puts "Received frame: #{frame.inspect}"

        if frame[:type] == :ping && frame[:payload].to_s.start_with?('1')
          puts 'PING!'
          conn.ping('33333333')
        end
      end

      conn.on(:stream) do |stream|
        log = Stenohttp2::Logger.new(stream.id)
        req = {}
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

          response = nil
          if req[':method'] == 'POST'
            log.info "Received POST request, payload: #{buffer}"
            response = "Hello HTTP 2.0! POST payload: #{buffer}"
          else
            log.info 'Received GET request'
            response = 'Hello HTTP 2.0! GET request'
          end

          stream.headers({
                           ':status' => '200',
                           'content-length' => response.bytesize.to_s,
                           'content-type' => 'text/plain'
                         }, end_stream: false)

          # split response into multiple DATA frames
          stream.data(response[0...5], end_stream: false)
          stream.data(response[5...-1])
       end
      end

      while !sock.closed? && !(begin
                               sock.eof?
                               rescue StandardError
                                 true
                             end)
        data = sock.readpartial(1024)
        # puts "Received bytes: #{data.unpack("H*").first}"

        begin
          conn << data
        rescue StandardError => e
          puts "#{e.class} exception: #{e.message} - closing socket."
          e.backtrace.each { |l| puts "\t" + l }
          sock.close
        end
    end
    end
  end

  private

  def server
    @server ||= begin
                  server = TCPServer.new(@port)
                  ctx = OpenSSL::SSL::SSLContext.new
                  ctx.cert = OpenSSL::X509::Certificate.new(File.open('keys/server.crt'))
                  ctx.key = OpenSSL::PKey::RSA.new(File.open('keys/server.key'))

                  ctx.ssl_version = :TLSv1_2
                  ctx.options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options]
                  ctx.ciphers = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers]

                  ctx.alpn_protocols = ['h2']

                  ctx.alpn_select_cb = lambda do |protocols|
                    if protocols.index(DRAFT).nil?
                      raise "Protocol #{DRAFT} is required"
                    end

                    DRAFT
                  end

                  ctx.ecdh_curves = 'P-256'

                  OpenSSL::SSL::SSLServer.new(server, ctx)
                end
  end
end

Server.new.start
