# frozen_string_literal: true

# typed: true
require 'securerandom'

module Stenohttp2
  module Server
class Server
  SERVER_IDENTIFIER = 'r2ssbxv8'

  def initialize(opts = {})
    @port = opts.fetch(:port, 8080)
    @server = ServerFactory.new(@port).start
  end

  # rubocop:disable Metrics/AbcSize
  def start
    puts "Server listening on https://localhost:#{port}"
    loop do
      sock = server.accept
      connection_handler = ConnectionHandler.new(sock).setup

      while !sock.closed? && !(begin
        sock.eof?
      rescue StandardError
        true
      end)
        data = sock.readpartial(1024)

        begin
          connection_handler.receive(data)
        rescue StandardError => e
          puts "#{e.class} exception: #{e.message} - closing socket."
          T.must(e.backtrace).each { |l| puts "\t#{l}" }
          sock.close
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  attr_reader :server, :port
end
  end
end
