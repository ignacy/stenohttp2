# typed: strict
require 'bundler/setup'
require 'stenohttp2'

require 'dotenv'
Dotenv.overload('.env.test')

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
