# typed: ignore
require 'dotenv'
Dotenv.load

require 'http/2'
require 'state_machines'
require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

module Stenohttp2
  class Error < StandardError; end
end

loader.eager_load
