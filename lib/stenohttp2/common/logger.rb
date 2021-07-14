# frozen_string_literal: true

# typed: true

require 'optparse'
require 'socket'
require 'openssl'
require 'http/2'
require 'uri'

DRAFT = 'h2'

module Stenohttp2
  module Common
  class Logger
    def initialize(id)
      @id = id
    end

    def info(msg)
      puts "[Stream #{@id}]: #{msg}"
    end
  end
  end
end
