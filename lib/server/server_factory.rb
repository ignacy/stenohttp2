# frozen_string_literal: true

# typed: true

require 'sorbet-runtime'
require_relative '../helper'

# Server factory creates HTTP2 ready TCP server and sets up SSL keys
class ServerFactory
  extend T::Sig

  sig { params(port: Integer).void }
  def initialize(port)
    @tcp_server = TCPServer.new(port)
  end

  def start
    OpenSSL::SSL::SSLServer.new(tcp_server, ctx)
  end

  private

  def ctx
    OpenSSL::SSL::SSLContext.new.tap do |ctx|
      ctx.cert = OpenSSL::X509::Certificate.new(File.open('keys/server.crt'))
      ctx.key = OpenSSL::PKey::RSA.new(File.open('keys/server.key'))
      ctx.ssl_version = :TLSv1_2
      ctx.options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options]
      ctx.ciphers = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers]
      ctx.alpn_protocols = ['h2']
      ctx.alpn_select_cb = lambda do |protocols|
        raise "Protocol #{DRAFT} is required" if protocols.index(DRAFT).nil?

        DRAFT
      end
      ctx.ecdh_curves = 'P-256'
    end
  end
  attr_reader :tcp_server
end
