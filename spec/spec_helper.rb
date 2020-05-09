# typed: strict
require "bundler/setup"
require "stenohttp2"
require_relative "../lib/protocol"
require_relative "../lib/framer"
require_relative "../lib/compressor"
require_relative "../lib/huffman_coder"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
