# typed: true

require 'listen'
require_relative 'framer'
require_relative 'compressor'
require_relative 'protocol'

class Watcher
  def initialize(dir)
    @dir = dir
  end

  def start
    listener = Listen.to(@dir, only: /\.message$/) do |modified, _added, _removed|
      if modified&.first
        puts "Found modifications to #{modified}"
        process(File.read(modified.first))
      end
    end
    listener.start
    sleep
  end

  private

  def process(data)
    numbers = data.split(/\s+/).reject(&:empty?).map(&:chomp)
    binaries = Framer.new.numbers_to_binary_string(numbers)
    decompressed = Compressor.decompress(binaries)
    message = Protocol.new.decode(decompressed)
    puts "Received message: #{message}"
  rescue StandardError
    puts 'Coudlnt read the data'
  end
end
