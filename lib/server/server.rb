# frozen_string_literal: true

# typed: true

require_relative './server_factory'
require_relative './connection_handler'
require_relative '../stenohttp2/helper'

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
      connection_handler = ConnectionHandler.new(sock).setup

      while !sock.closed? && !(begin
                               sock.eof?
                               rescue StandardError
                                 true
                             end)
        data = sock.readpartial(1024)
        # puts "Received bytes: #{data.unpack("H*").first}"

        begin
          connection_handler.receive(data)
        rescue StandardError => e
          puts "#{e.class} exception: #{e.message} - closing socket."
          T.must(e.backtrace).each { |l| puts "\t" + l }
          sock.close
        end
    end
    end
  end

  private

  attr_reader :server, :port
end
