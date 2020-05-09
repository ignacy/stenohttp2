# frozen_string_literal: true
# typed: true
$LOAD_PATH << 'lib' << '../lib'

require 'optparse'
require 'socket'
require 'openssl'
require 'http/2'
require 'uri'

DRAFT = 'h2'

module Stenohttp2
  class Logger
    def initialize(id)
      @id = id
    end

    def info(msg)
      puts "[Stream #{@id}]: #{msg}"
    end
  end
end