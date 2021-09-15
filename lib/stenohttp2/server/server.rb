# typed: true
# frozen_string_literal: true

require 'securerandom'
require 'uri'
require 'sorbet-runtime'

module Stenohttp2
  module Server
    class Server
      extend T::Sig

      sig { params(url: URI).void }
      def initialize(url:)
        @url = opts.fetch(:url)
        @port = URI(@url).port
        @server = ServerFactory.new(@port).start
      end

      def start
        puts "Server listening on #{url}"
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
              e.backtrace.each { |l| puts "\t#{l}" }
              sock.close
            end
          end
        end
      end

      private

      attr_reader :server, :port, :url
    end
  end
end
