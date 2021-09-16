# typed: ignore
# frozen_string_literal: true

require 'securerandom'
require 'uri'
require 'sorbet-runtime'

module Stenohttp2
  module Server
    class Server
      extend T::Sig
      BUFFER_SIZE = 1024

      sig { params(url: URI).void }
      def initialize(url:)
        @url = url
        @port = @url.port
        @server = ServerFactory.new(@port).start
      end

      # rubocop:disable Metrics/AbcSize
      def start
        log.info "Server listening on #{url}"

        loop do
          client_connection = server.accept

          Thread.start(client_connection) do |connection|
            connection_handler = ::Stenohttp2::Server::Handler.new(connection).setup

            while !connection.closed? && !(begin
              connection.eof?
            rescue StandardError
              true
            end)
              data = connection.readpartial(BUFFER_SIZE)

              begin
                connection_handler.receive(data)
              rescue StandardError => e
                log.error "#{e.class} exception: #{e.message} - closing connectionet."
                T.must(e.backtrace).each { |l| puts "\t#{l}" }
                connection.close
              end
            end
          end.join
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :server, :url

      def log
        @log ||= ::Stenohttp2::Common::Logger.new
      end
    end
  end
end
