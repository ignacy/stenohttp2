# typed: true
# frozen_string_literal: true

module Stenohttp2
  module Server
    # Server factory creates a HTTP2 ready TCP server and sets up SSL keys
    class ServerFactory
      def initialize(port)
        @tcp_server = TCPServer.new(port)
      end

      def start
        OpenSSL::SSL::SSLServer.new(tcp_server, ctx)
      end

      private

      # rubocop:disable Naming/VariableNumber
      def ctx
        OpenSSL::SSL::SSLContext.new.tap do |ctx|
          ctx.cert = OpenSSL::X509::Certificate.new(File.open('keys/server.crt'))
          ctx.key = OpenSSL::PKey::RSA.new(File.open('keys/server.key'))
          ctx.ssl_version = :TLSv1_2
          ctx.options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options]
          ctx.ciphers = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers]
          ctx.alpn_protocols = ['h2']
          ctx.alpn_select_cb = lambda do |protocols|
            raise 'Protocol h2 is required' if protocols.index('h2').nil?

            'h2'
          end
          ctx.ecdh_curves = 'P-256'
        end
      end
      # rubocop:enable Naming/VariableNumber

      attr_reader :tcp_server
    end
  end
end
