# frozen_string_literal: true

# typed: true

require_relative '../stenohttp2/helper'
require_relative './server_factory'

class Server
  def initialize(opts = {})
    @port = opts.fetch(:port) { 8080 }
    @server = ServerFactory.new(@port).start
  end

  def start
    puts "Server listening on https://localhost:#{port}"
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

          response = File.read(File.join("public", "index.html"))

          stream.headers({
                           ':status' => '200',
                           'content-length' => response.bytesize.to_s,
                           'content-type' => 'text/html'
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
          conn.receive(data)
        rescue StandardError => e
          puts "#{e.class} exception: #{e.message} - closing socket."
          e.backtrace.each { |l| puts "\t" + l }
          sock.close
        end
    end
    end
  end

  private

  attr_reader :server, :port
end
