# typed: strong

require 'dotenv'
Dotenv.load

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

module Stenohttp2
  class Error < StandardError; end
end

loader.eager_load
