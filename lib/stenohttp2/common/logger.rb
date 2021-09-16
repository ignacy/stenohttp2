# typed: true
# frozen_string_literal: true

require 'optparse'
require 'socket'
require 'openssl'
require 'http/2'
require 'uri'

module Stenohttp2
  module Common
    class Logger
      DEFAULT_STREAM_IDENTIFIER = 1

      def initialize(id = DEFAULT_STREAM_IDENTIFIER)
        @id = id
      end

      def info(msg)
        puts "[Stream #{@id}]: #{msg}"
      end
    end
  end
end
