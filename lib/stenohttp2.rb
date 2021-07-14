# typed: strong
require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

module Stenohttp2
  class Error < StandardError; end
end
