# typed: ignore
# frozen_string_literal: true

require 'securerandom'
require 'uri'
require 'sorbet-runtime'
require 'forwardable'

module Stenohttp2
  module Server
    class Server
      extend T::Sig
      extend Forwardable
      def_delegators :@url, :port

      sig { params(url: URI).void }
      def initialize(url:)
        @url = url
        @server = ServerFactory.new(@port).start
      end

      def start
        puts "Server listening on #{url}"
        loop do
          sock = server.accept
          connection_handler = ::Stenohttp2::Server::Handler.new(sock).setup

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

      private

      attr_reader :server, :url
    end
  end
end
